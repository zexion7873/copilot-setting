---
name: debug
description: 'Use when user reports a bug, error, exception, stack trace, or unexpected behavior and needs root cause analysis. Triggers on: debug, find bug, fix bug, exception thrown, stack trace, root cause, why does this fail, NPE, NullPointerException, 除錯, 找 bug, 這裡怪怪的, 報錯了, 為什麼會錯, 修 bug. Performs systematic isolation and minimal fix. Do NOT use for general "how to" questions, feature requests, known simple typo fixes, or performance tuning without a concrete error (prefer performance).'
---

# Debug — Workflow

Systematic isolation and minimal fix process.

Full coding standards live in `instructions/*.instructions.md` (auto-applied when matching files are open). When working via agent chat, these non-negotiable rules still apply:

- **SQL**: `PreparedStatement` with `?` only — never introduce string concatenation while fixing
- **Exceptions**: no empty `catch` blocks; fix the handler, don't add a new swallow point; never catch `Throwable`
- **Logging**: SLF4J parameterized — `log.info("x={}", x)` — remove all temporary debug logging before committing
- **Resources**: `try-with-resources` for all `AutoCloseable` — connection leaks are a common root cause, not just a style issue
- **Security**: no hardcoded secrets; verify fix doesn't bypass input validation or auth checks

## Phase 1 — Define the Problem

Capture before touching code:

```
Expected:      <what should happen>
Actual:        <what actually happens>
Error message: <exact text, not paraphrased>
Stack trace:   <full trace if available>
Reproducible:  always / sometimes / once
Since when:    recent change / always / unknown
```

Classify: Crash/Exception → stack trace analysis | Wrong result → compare expected vs actual at each step | Performance → profile hot path | Intermittent → look for shared mutable state | Silent failure → search empty catch blocks.

## Phase 2 — Gather Evidence

Read the stack trace bottom-up; the first line in YOUR code (not framework) is the entry point. Check recent git changes in the affected area and related call sites.

## Phase 3 — Form Hypotheses

List plausible causes ranked by likelihood. For each: what confirms it, what refutes it, effort to verify. **Verify lowest-effort hypothesis first.**

## Phase 4 — Isolate

Binary search on the execution path: identify entry and failure point, check midpoint state, narrow until divergence is one line. Use temporary diagnostic logging (remove before commit).

## Phase 5 — Verify Root Cause

Before fixing, confirm: Does the cause explain ALL symptoms? Is this the ROOT cause or a symptom? Could the same cause affect other code?

```
What:         <specific code / config / data issue>
Where:        <file, method, line>
Why:          <causal chain to observed behavior>
Blast radius: <what else might be affected>
```

## Phase 6 — Fix Minimally

- Fix only the root cause; do not refactor in a bugfix
- Smallest possible diff; don't change behavior beyond the fix
- Remove all temporary debug logging
- Search for the same pattern elsewhere; if found, log as separate findings

## Common Java 8 Traps

| Issue | Typical cause |
|---|---|
| `NullPointerException` | Missing null check, `Optional` misuse |
| `ConcurrentModificationException` | Modifying collection during iteration |
| Connection pool exhaustion | Unclosed connections on error paths |
| Deadlock | Inconsistent lock ordering |

## SQL-Related Debugging

- **Slow query** — `EXPLAIN`; check missing indexes or functions on indexed columns
- **N+1** — SQL inside loops
- **Connection leak** — verify try-with-resources on error paths
- **Wrong results** — implicit type conversion in WHERE / JOIN

## Handoffs

- → `@implementer` — to implement the fix after root cause is confirmed
- ← `@implementer` — when implementation reveals a deeper bug requiring systematic isolation
- ← `performance` skill — when a performance issue turns out to be a bug
