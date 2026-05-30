---
name: debug
description: 'Use when user reports a bug, error, exception, or unexpected behavior needing root cause analysis and minimal fix. Triggers on: debug, bug, exception, stack trace, root cause, why does this fail, NPE, 除錯, 找 bug, 報錯了, 為什麼會錯, 修 bug, 這裡怪怪的. Performs systematic isolation and minimal fix. Do NOT use for feature requests (prefer implement), performance tuning without a concrete error (prefer performance), or known simple typos (prefer implement).'
---

# Debug — Workflow

Systematic isolation and minimal fix.

**Canonical rules — open the instruction files for the layers you touch** (agent mode can read them directly):

- `instructions/java.instructions.md` — Java 8 language boundary
- `instructions/spring-hibernate.instructions.md` — Spring 3.2 + Hibernate 4.2
- `instructions/sql.instructions.md` — SQL injection, indexing, JDBC resources
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

## Phase 1 — Define the Problem

```
Expected:      <what should happen>
Actual:        <what actually happens>
Error/Trace:   <exact message, not paraphrased>
Reproducible:  always / sometimes / once
Since when:    recent change / always / unknown
```

## Phase 2 — Gather Evidence

Read stack trace bottom-up — first line in YOUR code is the entry point. Check recent git changes in the affected area.

## Phase 3 — Form Hypotheses

List causes ranked by likelihood. For each: what confirms it, what refutes it, effort to verify. **Verify lowest-effort hypothesis first.**

## Phase 4 — Isolate

Binary search on execution path: entry → failure point → check midpoint → narrow until divergence is one line.

## Phase 5 — Verify Root Cause

Before fixing: does the cause explain ALL symptoms? Is this the ROOT cause or a symptom? Could the same cause affect other code?

## Phase 6 — Propose Minimal Fix

- Specify the minimal fix for the root cause; do not propose refactoring in a bugfix
- Aim for the smallest possible diff
- Search for same pattern elsewhere; log as separate findings
- Hand off to `@implementer` for actual code changes

## Handoffs

- → `@implementer` — to implement the fix after root cause confirmed
- ← `@implementer` — when implementation reveals a deeper bug
- ← `performance` skill — when a performance issue turns out to be a bug
