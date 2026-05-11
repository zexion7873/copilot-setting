---
name: debug
description: 'Use when user reports a bug, error, exception, stack trace, or unexpected behavior and needs root cause analysis. Also triggers on: 除錯, 找 bug, 這裡怪怪的, 報錯了, 為什麼會錯. Performs systematic isolation and minimal fix. Do NOT use for general "how to" questions, feature requests, or known simple typo fixes.'
---

# Debug — Workflow

Systematic isolation and minimal fix process. Stack-specific patterns (NPE, leaks, SQL) live in `agents/debugger.agent.md`. This file is the process.

## Phase 1 — Define the Problem

Capture this before touching code:

```
Expected:      <what should happen>
Actual:        <what actually happens>
Error message: <exact text, not paraphrased>
Stack trace:   <full trace if available>
Reproducible:  always / sometimes / once
Since when:    recent change / always / unknown
Environment:   dev / staging / production
```

Classify:

| Type | Typical cause | Investigation |
|---|---|---|
| Crash / Exception | Null ref, missing resource, type error | Stack trace → call chain |
| Wrong result | Logic error, stale cache, wrong query | Compare expected vs actual at each step |
| Performance | N+1, leak, unbounded loop | Profile, isolate hot path |
| Intermittent | Race, timing, external dep | Add logging; look for shared mutable state |
| Silent failure | Swallowed exception, missing error handling | Search empty catch, check return values |

## Phase 2 — Gather Evidence

Read the stack trace bottom-up; the first line in YOUR code (not framework) is the entry point.

```bash
# Recent changes in the affected area
git log --oneline -20 -- path/to/affected/
git log -p -5 -- path/to/affected/File.java
git log -1 -S "problematic snippet" -- "*.java"

# Related call sites and patterns
grep -rn "methodName" --include="*.java" src/
grep -rn "catch.*ExceptionType" --include="*.java" src/

# Logs
grep -n "ERROR\|Exception\|WARN" log/file.log | tail -50
grep -B5 -A10 "specific error" log/file.log
```

## Phase 3 — Form Hypotheses

List plausible causes ranked by likelihood. For each note: what would confirm it, what would refute it, effort to verify.

**Verify the lowest-effort hypothesis first.** Don't jump to the most exciting theory.

## Phase 4 — Isolate

Binary search on the execution path:

1. Identify entry point and failure point
2. Pick the midpoint
3. Check whether state is correct there
   - Correct → bug is in the second half
   - Wrong → bug is in the first half
4. Repeat until the divergence is one line

Diagnostic logging (temporary — remove before commit):

```java
log.debug("[DEBUG] {} entry — p1={}, p2={}", "methodName", param1, param2);
log.debug("[DEBUG] after query — resultSize={}", results.size());
log.debug("[DEBUG] branch — value={}, willProcess={}", value, value > THRESHOLD);
```

Reproduce minimally: start from full repro, remove variables one at a time, document the minimal set.

## Phase 5 — Verify Root Cause

Before writing any fix, answer:

- Does the cause explain ALL symptoms, not just some?
- Can you predict behavior on different inputs?
- Is this the ROOT cause or a symptom? (Keep asking "but why?")
- Could the same cause affect other parts of the code?

Root cause statement:

```
What:         <specific code / config / data issue>
Where:        <file, method, line>
Why:          <causal chain to observed behavior>
Since:        <when introduced, if known>
Blast radius: <what else might be affected>
```

## Phase 6 — Fix Minimally

- Fix only the root cause; do not refactor in a bugfix
- Smallest possible diff
- Don't change behavior beyond the fix
- Remove all temporary debug logging

Verify:

```bash
mvn test -pl <module>                                # module tests
mvn test -pl <module> -Dtest=<AffectedClass>Test    # focused
mvn test                                              # regression sweep
```

## Phase 7 — Prevent Recurrence

Write a regression test that would have FAILED before the fix and PASSES after. Name: `testX_shouldDoY_whenZ`.

Search for the same pattern elsewhere:

```bash
grep -rn "similar pattern" --include="*.java" src/
```

If found, log as separate findings — do NOT bundle into this bugfix.

Fix summary for the PR:

```
Bug:        <one-line>
Root cause: <one-line>
Fix:        <what changed, why>
Test:       <regression test added>
Related:    <other occurrences, if any>
```

## Debug Anti-Patterns

- Shotgun debugging (random changes) → follow binary search
- Fixing symptoms not root cause → bug reappears in another form
- Refactoring while debugging → introduces new variables, harder to isolate
- Assuming you know the cause → confirmation bias; verify with data
- No regression test → same bug returns
- Leaving debug logging in → log noise in production
