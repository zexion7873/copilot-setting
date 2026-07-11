---
name: verify
description: 'Use when checking whether an implementation actually meets its acceptance criteria — derive the checks, bind each to a runnable command, execute, and gate pass/fail so a build loop has an objective exit condition. Triggers on: verify, does it pass, acceptance check, definition of done, test cases, what to test, 驗證, 驗收, 過了沒, 測試案例, 要測什麼. Produces a verification document binding each criterion to an executable check with a recorded result. Do NOT use for writing production or test code (prefer implement), general quality review (prefer code-review), or diagnosing a known failure (prefer debug).'
---

# Verify — Workflow

Close-the-loop verification: derive what must be true, bind each to a runnable check, execute, and gate. The gate is a separate pass from authoring — derive the expected behaviour from the requirement, never from the code under test, or the gate just rubber-stamps whatever the code does. Framework rules for any run command or test code referenced here: `instructions/testing.instructions.md`.

## Phase 0 — Load canonical rules

**MANDATORY pre-load gate — do NOT derive or run checks until you have opened the instruction files for the layers under verification.** Your training data defaults to modern Java/Spring; these files are the version lock for Java 8 / Spring 3.2 / Hibernate 4.2. Open them first, every time:

- `instructions/testing.instructions.md` — JUnit 4 / Mockito / Spring Test 3.2 — every run command and any test code must match this stack, not JUnit 5 / Spring Boot Test
- The layer instruction(s) for the feature under verification (e.g. `instructions/sql.instructions.md`, `instructions/security.instructions.md`) — their Anti-Patterns are the negative cases Phase 1 must cover

Read-back receipt (self-check, not machine-enforced): before leaving this step, NAME each instruction file you opened above and QUOTE the single most load-bearing rule from each that applies to this verification — a generic restatement you could have written from memory means you skipped the file, so open it for real.

## Phase 1 — Derive the checks

Work from the requirement / `plan.md` acceptance criteria (AC-NNN), NOT from the code under test — independent derivation is the whole point of a gate.

- **Boundaries** — input (min, max, empty, null, overflow), state (initial, in-progress, done, error), integration (external call, DB, file I/O)
- **Categories** — tag each check: Happy path, Boundary, Error / Exception, Security, Concurrency, Performance
- **Coverage** — every AC maps to ≥1 check; every public method has ≥1 happy + ≥1 error; boundary values for all numeric/string inputs; SQL paths checked for injection and empty results

## Phase 2 — Bind each check to a runnable command

Every check gets a concrete, binary oracle — a command plus its expected observable. A check with no runnable command is a documentation item, not a gate: mark it `MANUAL` and exclude it from the automated pass/fail count.

- `mvn -Dtest=<Class>#<method> test` for one behaviour; `mvn test` for the suite
- Expected result stated as an observable — exit 0, a specific assertion, a DB state, an HTTP status — never "looks correct"

## Phase 3 — Run and record

Execute every bound check. Record the ACTUAL result against the expected — never infer a pass from the diff or from "it should work". A check you did not run is `UNRUN`, not a pass.

## Phase 4 — Gate

- ALL bound checks green → **PASS**; the loop may close.
- ANY red → **FAIL**; hand back to `@implementer` with the failing checks and their raw output. Never soften a red to "mostly done" — the exit condition is binary.
- List every `MANUAL` / `UNRUN` check explicitly. A gate that hides them reports a false green.

## Output Template

Write to `docs/plans/<feature>/verification.md` — the same per-feature folder as the plan it verifies (create the folder if absent). Versioning is git history, not a `-vN` suffix.

```md
---
source: <plan path or feature under verification>
date: <YYYY-MM-DD>
---

# Verification — <component>

## Checks

VC-NNN: <short description>
Category: <Happy path | Boundary | Error | Security | Concurrency | Performance>
Criterion: <the AC-NNN or requirement this proves>
Command: <runnable command — or MANUAL: why it cannot be automated>
Expected: <observable pass condition>
Result: <PASS | FAIL | UNRUN> — <actual observed>

## Gate

Status: <PASS | FAIL>
Bound checks: <N passed / M total>   Manual/unrun: <k>
Blocking failures: <VC-NNN list, or none>
```

## Anti-Patterns

- Deriving checks from the code under test instead of the requirement → the gate rubber-stamps whatever the code happens to do
- A check with no runnable command counted toward the pass → false green; mark `MANUAL` and exclude it from the automated count
- "Should pass" / inferring a result from the diff → a check you did not run is `UNRUN`, never a pass
- Softening a red to "mostly done" to close the loop → the exit condition is binary; a fail is a fail

## Handoffs

- → `@implementer` — when the gate FAILS, to fix the failing checks (loop back)
