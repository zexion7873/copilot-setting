---
name: code-review
description: 'Use when user asks to review code, check a PR, audit changes, or verify code against a plan. Triggers on: review code, check PR, audit changes, code review, verify against plan, 審查程式碼, 看一下這段 code, 幫我 review, 程式碼審查, 檢查 PR. Performs structured review with issue classification and verdict focused on correctness, style, and bug patterns. Do NOT use for simple "what does this code do" explanations, refactoring requests (prefer refactor), when user request is vague and needs scope clarification (prefer clarify-task), or for spec compliance verification post-implementation (prefer sdd-compliance skill — that focuses on AC traceability and requirements coverage).'
---

# Code Review — Workflow

Process for systematic code review. This file defines the order of attack, severity classification, and verdict shape. Category-level checklist (correctness, security, testing, performance, architecture, documentation, clean code) lives in `prompts/code-review-checklist.prompt.md`.

Full coding rules live in `instructions/` (auto-applied when matching files are open). When working via agent chat, check against these non-negotiable rules:

- **SQL**: `PreparedStatement` with `?` only — string concatenation is always CRITICAL; no `SELECT *`; N+1 = SQL inside a loop
- **Exceptions**: no empty `catch` blocks; no `catch (Throwable)`; no `e.printStackTrace()` — use `log.error("context", e)`
- **Logging**: SLF4J parameterized — `log.info("x={}", x)` — never `+` concatenation; never log secrets/PII
- **Resources**: `try-with-resources` for all `AutoCloseable` (`Connection`, `PreparedStatement`, `ResultSet`, `InputStream`)
- **Security**: no hardcoded secrets; `<c:out>` for all dynamic output in JSP; validate inputs at boundaries
- **Tests**: `methodName_should_when` naming; AAA pattern; `@ParameterizedTest` over loops; mock interfaces not concretions

## Phase 1 — Scope

```bash
git diff --name-only main...HEAD       # branch vs main
git diff --staged --name-only          # staged changes
git diff --name-only <c1>..<c2>        # specific commits
git diff --stat main...HEAD            # summary
```

Classify the change to focus the review:

| Type | Review focus |
|---|---|
| New feature | Requirements met? Edge cases? Tests? |
| Bug fix | Root cause fix? Regression risk? |
| Refactor | Behavior preserved? Tests still pass? |
| Config / infra | Security? Environment differences? |
| SQL / migration | Reversibility? Performance? Data integrity? |

Look for an associated plan / ADR / ticket. If one exists, the review MUST verify compliance.

## Phase 2 — Read the Diff

Read in this order to build understanding incrementally:

1. Data layer — models, entities, migrations, SQL
2. Business logic — services, handlers, processors
3. Interface — controllers, APIs, CLI
4. Configuration — properties, XML, POM
5. Tests — verify they cover changes above

Per-file checks: purpose clear, scope respected, side effects identified, completeness (error handling, logging, validation).

Cross-file checks: naming / pattern consistency, transaction boundaries, thread safety, no circular deps.

## Phase 3 — Plan Compliance

For each step in the plan: is it implemented? does it match intent? deviations justified?

Report deviations as:

```
DEVIATION: Plan step N
  Plan said: <what was specified>
  Code does: <what was implemented>
  Impact:    Low / Medium / High
  Justified: Yes (reason) / No (must correct)
```

## Phase 4 — Classify Findings

Severity buckets and issue format defined in `prompts/code-review-checklist.prompt.md` — apply them here.

## Phase 5 — Verdict

| Findings | Verdict |
|---|---|
| 0 CRITICAL, 0 WARNING | APPROVED — ready to merge |
| 0 CRITICAL, 1+ WARNING | APPROVED WITH COMMENTS — address before merge |
| 1+ CRITICAL | CHANGES REQUESTED — must fix |

Final report skeleton:

```
## Review Verdict: <APPROVED / APPROVED WITH COMMENTS / CHANGES REQUESTED>

Scope: <what was reviewed>
Plan compliance: <fully compliant / N deviations / no plan referenced>

Counts: CRITICAL N / WARNING N / SUGGESTION N

What's good:
- <positive observation>

Must fix:
1. <CRITICAL summary linking to detail>

Should fix:
1. <WARNING summary linking to detail>
```

## Handoffs

- → `@implementer` — to fix issues or refactor based on review findings
- → `@planner` — when fundamental design problems require re-planning
- ← `implement` skill — implementation completion triggers review
- ← `refactor` skill — refactored code needs re-review

## Anti-Patterns

- Rubber-stamp approval → defeats the review
- Style-only feedback → misses real issues
- Rewrite suggestions → scope creep; file separately
- No positive feedback → demoralizing, misses chance to reinforce patterns
- Reviewing without running code → static analysis misses runtime issues
