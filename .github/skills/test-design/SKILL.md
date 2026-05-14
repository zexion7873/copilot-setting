---
name: test-design
description: 'Use when user asks to design tests, plan test coverage, or identify what to test. Triggers on: design tests, plan test coverage, identify what to test, test cases, boundary cases, edge cases, coverage gap, 寫測試, 測試案例, 要測什麼, 補 test, 測試覆蓋率, 該測哪些情境, 邊界測試. Designs test cases with boundary analysis, category classification, and coverage gap audit; hand off to @implementer for coding. Do NOT use for running existing tests, fixing test infrastructure, or debugging test failures — prefer debug skill for that.'
---

# Test Design — Workflow

Process for designing tests systematically. Targets JUnit 5 + Mockito — coding conventions defined in `instructions/junit.instructions.md`. This file defines HOW to design, not coding standards.

## Phase 1 — Analyze the Code Under Test

For each method capture:

- Signature: name, return type, parameters, declared exceptions, visibility
- All branches: if/else, switch cases, try/catch, early returns, loops, Optional chains, Stream stages
- Inputs: direct params, fields read, external reads (DB, file, cache)
- Outputs: return values, thrown exceptions
- Side effects: DB writes, file writes, cache puts, external calls, state mutations
- Dependencies to mock: list each one

## Phase 2 — Identify Boundaries

Run every parameter through these axes:

| Type | Boundary values to test |
|---|---|
| **Null / Empty** | `null`, `""`, `"   "` blank, `[]` empty collection, `Optional.empty()` |
| **Numeric** | `0`, `-1`, `MIN_VALUE`, `MAX_VALUE`, domain min/max, one past each boundary, double precision (`0.1+0.2`) |
| **Collection** | size 0, 1, 2 (ordering), N (typical), MAX (perf); `null` vs `[]` |
| **String** | `null`, `""`, `" "`, single char, max length, max+1, special chars, Unicode (中文/emoji), SQL probe (`' " ; --`), HTML probe (`< > &`) |
| **Date / Time** | `null`, epoch, leap year Feb 29, non-leap Feb 29, month/year end, midnight UTC vs local, DST |
| **Concurrency** | concurrent read, concurrent write, read-write interleave (if shared state) |

## Phase 3 — Design Cases by Category

One row per test:

```
| # | Category | Test Name | Input | Expected | Priority |
```

Categories:

- **Happy Path (P0)** — One per distinct normal scenario
- **Alternative Paths (P0-P1)** — One per branch that changes behavior
- **Error Paths (P1)** — One per declared exception type
- **Boundary Values (P1)** — One per boundary identified in Phase 2
- **Integration (P2)** — One per dependency interaction (success/failure/timeout)
- **Security (P2)** — One per attack vector (injection, auth bypass)

## Phase 4 — Hand Off for Implementation

Test case design is complete. For coding the tests:

- → `@implementer` (Test Design Mode) — writes JUnit 5 + Mockito code from the design table above
- → `instructions/junit.instructions.md` — auto-applied conventions for test files (naming, AAA, assertions, mocking)

Do not write test code in this skill. Separation ensures the design is reviewed before implementation begins.

## Phase 5 — Coverage Gap Audit

Branch coverage:

- Each `if/else`: both branches tested
- Each `switch`: every case + default
- Each `try/catch`: happy path + each caught exception type
- Each guard / early return: triggered + pass-through

Dependency interactions:

- Success response
- Empty / null response
- Exception response
- `verify()` called with correct args
- `verify(_, never())` when it shouldn't be called

Make tests resilient to mutation testing:

- Boundary flip (`>` vs `>=`) → test the exact boundary
- Return value flip → assert exact value, not truthiness
- Condition negation → test both branches
- Removed method call → use `verify()`
- Arithmetic operator swap → assert exact result

## Handoffs

- → `@implementer` (Test Design Mode) — writes JUnit 5 + Mockito code from the design table
- → `instructions/junit.instructions.md` — auto-applied conventions for test files (naming, AAA, assertions, mocking)
- ← `implement` skill — implementation may trigger test design for new functionality
- ← `code-review` skill — review may flag coverage gaps needing test design

## Anti-Patterns

Anti-patterns and coding conventions for JUnit 5 + Mockito are defined in `instructions/junit.instructions.md` (auto-applied on test files). Key reminders:

- Test behavior, not implementation → assert returns + side effects, not call sequence
- Every test asserts at least once → a test with no `assert*` always passes
- Only mock dependencies → never mock the class under test
- `assertEquals(expected, actual)` → never `assertTrue(a.equals(b))`

## Quick Checklist (small methods)

Valid input? `null`? Min/max? One past boundary? Exceptions? Dependencies (`verify`)? Collection size 0/1/many? State mutation before/after? Security (injection, unauthorized)?
