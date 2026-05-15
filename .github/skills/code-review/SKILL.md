---
name: code-review
description: 'Use when user asks to review code, check a PR, audit changes, or verify code against a plan. Triggers on: review code, check PR, audit changes, code review, verify against plan, 審查程式碼, 看一下這段 code, 幫我 review, 程式碼審查, 檢查 PR. Performs structured review with issue classification and verdict focused on correctness, style, and bug patterns. Do NOT use for simple "what does this code do" explanations, refactoring requests (prefer refactor), or when user request is vague and needs scope clarification (prefer clarify-task).'
---

# Code Review — Workflow

Process for systematic code review. Category-level checklist lives in `prompts/code-review-checklist.prompt.md`.

Full coding rules live in `instructions/*.instructions.md` (auto-applied when matching files are open). When working via agent chat, check against these non-negotiable rules:

- **SQL**: `PreparedStatement` with `?` only — string concatenation is always CRITICAL; no `SELECT *`; N+1 = SQL inside a loop
- **Exceptions**: no empty `catch` blocks; no `catch (Throwable)`; no `e.printStackTrace()` — use `log.error("context", e)`
- **Logging**: SLF4J parameterized — never `+` concatenation; never log secrets/PII
- **Resources**: `try-with-resources` for all `AutoCloseable`
- **Security**: no hardcoded secrets; `<c:out>` for all dynamic output in JSP; validate inputs at boundaries

## Phase 1 — Scope

Identify what changed and classify the change type to focus the review:

| Type | Review focus |
|---|---|
| New feature | Requirements met? Edge cases? |
| Bug fix | Root cause fix? Regression risk? |
| Refactor | Behavior preserved? |
| Config / infra | Security? Environment differences? |
| SQL / migration | Reversibility? Performance? Data integrity? |

Look for an associated plan / SDD. If one exists, verify compliance.

## Phase 2 — Read the Diff

Read in order: Data layer → Business logic → Interface → Configuration. Per-file: purpose clear, scope respected, error handling present. Cross-file: naming consistency, transaction boundaries, no circular deps.

## Phase 3 — Plan Compliance

If a plan or SDD exists, verify each step is implemented correctly. Report deviations with impact level (Low/Medium/High) and whether justified.

## Phase 4 — Classify Findings

Severity buckets and format defined in `prompts/code-review-checklist.prompt.md`.

## Phase 5 — Verdict

| Findings | Verdict |
|---|---|
| 0 CRITICAL, 0 WARNING | APPROVED |
| 0 CRITICAL, 1+ WARNING | APPROVED WITH COMMENTS |
| 1+ CRITICAL | CHANGES REQUESTED |

## Handoffs

- → `@implementer` — to fix issues or refactor based on review findings
- → `@planner` — when fundamental design problems require re-planning
- ← `implement` skill — implementation completion triggers review
- ← `refactor` skill — refactored code needs re-review
