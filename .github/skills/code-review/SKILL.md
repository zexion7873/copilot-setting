---
name: code-review
description: 'Use when user asks to review code, check a PR, audit changes, 審查程式碼, 看一下這段 code, 幫我 review, or verify code against a plan. Performs structured review with issue classification and verdict. Do NOT use for simple "what does this code do" explanations or refactoring requests.'
---

# Code Review — Workflow

Process for systematic code review. Standards (what to check by category) live in `prompts/code-review-checklist.prompt.md`. This file defines the order of attack, severity classification, and verdict shape.

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

Apply standards from `prompts/code-review-checklist.prompt.md`. Severity buckets:

```
CRITICAL    Must fix before merge
            Security vuln, data loss risk, crash on main path, breaking API change

WARNING     Should fix; discuss if blocking
            Performance issue, missing error handling, test gap, pattern deviation

SUGGESTION  Non-blocking improvement
            Naming, simplification opportunity, minor inconsistency
```

Issue format:

```
[SEVERITY] Category — Title
  File: path/to/File.java#method:line
  Problem: <what + why it matters>
  Fix: <specific suggestion, with code if applicable>
```

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

## Review Anti-Patterns

- Rubber-stamp approval → defeats the review
- Style-only feedback → misses real issues
- Rewrite suggestions → scope creep; file separately
- No positive feedback → demoralizing, misses chance to reinforce patterns
- Reviewing without running code → static analysis misses runtime issues
