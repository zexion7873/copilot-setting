---
name: test-design
description: 'Use when user needs test case identification and documentation — boundary analysis, category classification, and coverage gap audit. Triggers on: test cases, what should we test, test plan, test design, 測試案例, 要測什麼, 測試規劃, 列測試項目. Produces a test case document (not test code). Do NOT use for implementation (prefer implement), code review (prefer code-review), or debugging (prefer debug).'
---

# Test Design — Workflow

Test case identification and documentation. Produces a structured document, not executable code.

## What to Identify

- **Input boundaries**: min, max, empty, null, overflow
- **State boundaries**: initial, in-progress, completed, error
- **Integration boundaries**: external APIs, DB operations, file I/O

## Categories & Priority

| Category | Priority |
|---|---|
| Happy path (normal flow, valid inputs) | Must have |
| Boundary (edge values at limits) | Must have |
| Error / Exception (invalid input, unavailable deps) | Must have |
| Security (injection, auth bypass) | Must have for user-facing |
| Concurrency (shared state, race conditions) | If multi-threaded |
| Performance (response time, throughput) | If SLA exists |

## Test Case Format

```
TC-NNN: <description>
Category: <category>
Precondition: <setup>
Input: <specific values>
Expected: <exact outcome>
Priority: High / Medium / Low
```

## Coverage Check

- Every requirement maps to ≥1 test case
- Every public method has ≥1 happy path + ≥1 error case
- Boundary values covered for all numeric/string inputs
- SQL operations tested for injection and empty results

## Handoffs

- ← `@implementer` — after implementation, to verify coverage
- ← `sdd` skill — to design tests from specification
