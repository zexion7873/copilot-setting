---
name: test-design
description: 'Use when user needs test case identification and documentation — boundary analysis, category classification, and coverage gap audit. Triggers on: test cases, what should we test, test plan, test design, design tests, 測試案例, 要測什麼, 測試規劃, 列測試項目. Produces a test case document (not test code). Do NOT use for implementation (prefer implement), code review (prefer code-review), or debugging (prefer debug).'
---

# Test Design — Workflow

Test case identification and documentation. Produces a structured test case document, not executable test code.

Framework rules for any test code that follows from this design: `../../instructions/testing.instructions.md`.

## Phase 1 — Identify Boundaries

From the feature/code under test, extract:
- Input boundaries: min, max, empty, null, overflow
- State boundaries: initial, in-progress, completed, error
- Integration boundaries: external API calls, DB operations, file I/O

## Phase 2 — Classify Categories

| Category | What to test | Priority |
|---|---|---|
| Happy path | Normal flow with valid inputs | Must have |
| Boundary | Edge values at limits | Must have |
| Error / Exception | Invalid input, unavailable deps, timeout | Must have |
| Security | Injection, auth bypass, privilege escalation | Must have for user-facing |
| Concurrency | Shared state, race conditions | If multi-threaded |
| Performance | Response time, throughput under load | If SLA exists |

## Phase 3 — Coverage Audit

Audit the test cases identified in Phases 1–2 before writing them up:

- [ ] Every requirement from the feature maps to ≥1 test case
- [ ] Every public method has at least one happy path + one error case
- [ ] Boundary values covered for all numeric/string inputs
- [ ] SQL operations tested for injection and empty result sets

## Phase 4 — Write Test Case Document

Write to `docs/test-design/[component]-tests-v[N].md` (create the directory if absent), beside the plan it derives from. Wrap the cases in a fixed skeleton so `@implementer` has a stable structure to read:

```md
---
source: <plan path or feature under test>
date: <YYYY-MM-DD>
---

# Test Design — <component>

## Boundaries

<Phase 1 output: input / state / integration boundaries>

## Test Cases

TC-NNN: <Short description>
Category: <Happy path | Boundary | Error | Security | Concurrency | Performance>
Precondition: <Setup required>
Input: <Specific values>
Expected result: <Exact expected outcome>
Priority: <High | Medium | Low>

## Coverage Audit

<Phase 3 coverage audit results>
```

## Handoffs

- → `@implementer` — to write test code based on this design
- → `@reviewer` — to review the implemented test code (`code-review`)
