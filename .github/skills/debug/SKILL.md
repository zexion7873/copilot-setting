---
name: debug
description: 'Systematic debugging workflow for reproducing, isolating, and fixing bugs. Use when user reports a bug, error, exception, or unexpected behavior. Walks through: problem definition, evidence gathering, hypothesis ranking, binary search isolation, root cause identification, minimal fix, and regression prevention. Designed for @debugger agent but usable by any agent troubleshooting issues.'
license: MIT
allowed-tools: ['search', 'read/problems', 'read/terminalLastCommand', 'execute/runInTerminal']
---

# Debug — Executable Workflow

## Overview

A structured debugging process that replaces "read code and guess" with systematic isolation and verification. This skill defines HOW to debug, not WHAT to look for (that's in the agent prompt).

## When to Use

- User reports a bug, error, or unexpected behavior
- Stack trace or error message provided
- Something "used to work" and now doesn't
- Intermittent or hard-to-reproduce issues
- User asks "why is this happening", "fix this error", "this is broken"

---

## Phase 1 — Define the Problem

Before touching any code, get a clear problem statement.

### 1.1 Collect Facts

Ask or determine these (do not skip any):

```
PROBLEM STATEMENT:
  Expected behavior: [what should happen]
  Actual behavior:   [what actually happens]
  Error message:     [exact text, not paraphrased]
  Stack trace:       [full trace if available]
  Reproducible:      [always / sometimes / once]
  Since when:        [recent change / always / unknown]
  Environment:       [dev / staging / production]
```

### 1.2 Classify the Bug

| Type | Typical Cause | Investigation Approach |
|------|--------------|----------------------|
| Crash / Exception | Null ref, missing resource, type error | Read stack trace → trace call chain |
| Wrong result | Logic error, stale cache, wrong query | Compare expected vs actual at each step |
| Performance | N+1 query, resource leak, unbounded loop | Profile, measure, isolate hot path |
| Intermittent | Race condition, timing, external dependency | Add logging, look for shared mutable state |
| Silent failure | Swallowed exception, missing error handling | Search for empty catch blocks, check return values |

---

## Phase 2 — Gather Evidence

### 2.1 Read the Stack Trace (if available)

```
Stack trace reading order:
1. Start at the BOTTOM — that's the entry point
2. Scan UP to find the FIRST line in YOUR code (not framework/library)
3. That line is your starting point for investigation
4. Read the exception message at the TOP for context
```

### 2.2 Check Recent Changes

```bash
# What changed recently in the affected area?
git log --oneline -20 -- path/to/affected/

# Show the actual diff of recent changes
git log -p -5 -- path/to/affected/File.java

# Find when a specific line was last changed
git log -1 -S "problematic code snippet" -- "*.java"
```

### 2.3 Search for Related Patterns

```bash
# Find all usages of the failing method
grep -rn "methodName" --include="*.java" src/

# Find similar error handling patterns
grep -rn "catch.*ExceptionType" --include="*.java" src/

# Find configuration that might affect behavior
grep -rn "config.key.name" --include="*.properties" --include="*.xml" .
```

### 2.4 Check Logs

```bash
# Search for the error in log files
grep -n "ERROR\|Exception\|WARN" path/to/log/file.log | tail -50

# Get context around the error
grep -B5 -A10 "specific error message" path/to/log/file.log
```

---

## Phase 3 — Form and Rank Hypotheses

### 3.1 List Possible Causes

Based on evidence, list ALL plausible causes:

```
HYPOTHESES (ranked by likelihood):
  1. [Most likely] — Evidence: [what supports this]
  2. [Second most likely] — Evidence: [what supports this]
  3. [Less likely] — Evidence: [what supports this]
```

### 3.2 Decide What to Verify First

For each hypothesis, define the verification step:

```
Hypothesis 1: [description]
  To confirm: [what to check — specific file, variable, log line]
  To refute:  [what would disprove this]
  Effort:     [Low/Medium/High]
```

**Always verify the lowest-effort hypothesis first.**

---

## Phase 4 — Isolate the Root Cause

### 4.1 Binary Search Method

When the bug is in a large code path, use binary search:

```
1. Identify the ENTRY POINT (where execution starts)
2. Identify the FAILURE POINT (where the error occurs)
3. Find the MIDPOINT in the execution path
4. Check if data/state is correct at the midpoint
   - If correct → bug is in the SECOND half
   - If wrong → bug is in the FIRST half
5. Repeat until you find the exact line where behavior diverges
```

### 4.2 Add Diagnostic Logging (Temporary)

When you need to trace execution:

```java
// Temporary debug logging — REMOVE before commit
log.debug("[DEBUG] methodName entry — param1={}, param2={}", param1, param2);

// Check state at critical points
log.debug("[DEBUG] after query — resultSize={}, firstItem={}", 
    results.size(), results.isEmpty() ? "empty" : results.get(0));

// Verify branch taken
log.debug("[DEBUG] condition check — value={}, threshold={}, willProcess={}", 
    value, THRESHOLD, value > THRESHOLD);
```

### 4.3 Reproduce Minimally

Try to find the smallest input that triggers the bug:

```
1. Start with the full reproduction case
2. Remove variables one at a time
3. Find the minimal set of conditions needed
4. Document the minimal reproduction steps
```

---

## Phase 5 — Verify Root Cause

Before writing ANY fix, verify you've found the actual root cause.

### 5.1 Root Cause Verification Checklist

```
□ Can you explain WHY this causes the observed behavior?
□ Does the root cause explain ALL symptoms (not just some)?
□ Can you predict what would happen with different inputs?
□ Is this the ROOT cause or just a SYMPTOM?
   (Ask: "But why does THIS happen?" — if you can answer, go deeper)
□ Could the same root cause affect other parts of the code?
```

### 5.2 Root Cause Statement

Write a clear root cause statement:

```
ROOT CAUSE:
  What: [the specific code/config/data issue]
  Where: [file, method, line]
  Why: [why this causes the observed behavior]
  Since: [when this was introduced, if known]
  Blast radius: [what else might be affected]
```

---

## Phase 6 — Fix Minimally

### 6.1 Fix Rules

| Rule | Why |
|------|-----|
| Fix ONLY the root cause | Don't refactor during a bugfix |
| Smallest possible change | Minimize regression risk |
| Don't change behavior beyond the fix | Keep the diff reviewable |
| Remove all temporary debug logging | Clean up after yourself |

### 6.2 Fix Verification

```
VERIFICATION:
  1. The original error no longer occurs:
     [describe how to verify — command, test, manual check]
  
  2. The expected behavior now works:
     [describe expected output/state]
  
  3. No regression in related functionality:
     [list what else to check]
```

### 6.3 Run Existing Tests

```bash
# Run tests for the affected module
mvn test -pl module-name

# Run a specific test class
mvn test -pl module-name -Dtest=AffectedClassTest

# Run the full test suite to check for regressions
mvn test
```

---

## Phase 7 — Prevent Recurrence

### 7.1 Write a Regression Test

Every bugfix SHOULD have a test that:

```
1. Reproduces the original bug scenario (would have FAILED before the fix)
2. Verifies the correct behavior (PASSES after the fix)
3. Is named descriptively: testMethodName_shouldDoX_whenConditionY
```

### 7.2 Check for Similar Patterns

```bash
# Search for the same pattern elsewhere in the codebase
grep -rn "similar problematic pattern" --include="*.java" src/

# If found, document them for a separate fix (not in this bugfix)
```

### 7.3 Document the Fix

```
FIX SUMMARY:
  Bug: [one-line description]
  Root cause: [one-line root cause]
  Fix: [what was changed and why]
  Test: [what test was added]
  Related: [other occurrences of the same pattern, if any]
  Commit: [conventional commit message suggestion]
```

---

## Common Java 8 Debug Patterns

### NullPointerException

```
Checklist:
□ Is the variable initialized?
□ Does the method return null on any code path?
□ Is Optional.get() called without isPresent()?
□ Is a collection element accessed without null check?
□ Is a map.get() result used without null check?
```

### Connection / Resource Leak

```
Checklist:
□ Is try-with-resources used for AutoCloseable?
□ Is the resource closed in the finally block?
□ Is the resource closed on ALL code paths (including error paths)?
□ Is the connection pool sized correctly?
□ Are connections returned to pool after use?
```

### ConcurrentModificationException

```
Checklist:
□ Is a collection modified during iteration?
□ Is a shared collection accessed from multiple threads?
□ Is Iterator.remove() used instead of Collection.remove()?
□ Should this use CopyOnWriteArrayList or ConcurrentHashMap?
```

### OutOfMemoryError

```
Checklist:
□ Is there an unbounded cache or collection?
□ Are large result sets loaded entirely into memory?
□ Is there a static collection that grows indefinitely?
□ Are event listeners / callbacks properly deregistered?
□ Is there a recursive call without proper termination?
```

---

## Debug Anti-Patterns

| Anti-Pattern | Why It Fails | Do This Instead |
|-------------|-------------|-----------------|
| Shotgun debugging (random changes) | Wastes time, may mask the real issue | Follow the binary search method |
| Fixing symptoms instead of root cause | Bug will reappear in a different form | Keep asking "but WHY?" |
| Refactoring while debugging | Introduces new variables, harder to isolate | Fix first, refactor separately |
| Assuming you know the cause | Confirmation bias skips real evidence | Verify hypotheses with data |
| No regression test | Same bug can come back | Always add a test |
| Leaving debug logging in | Noise in production logs | Remove before commit |
