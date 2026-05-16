---
name: debug
description: 'Use when user reports a bug, error, exception, or unexpected behavior needing root cause analysis and minimal fix. Triggers on: debug, bug, exception, stack trace, root cause, why does this fail, NPE, 除錯, 找 bug, 報錯了, 為什麼會錯, 修 bug, 這裡怪怪的. Performs systematic isolation and minimal fix. Do NOT use for feature requests (prefer implement), performance tuning without a concrete error (prefer performance), or known simple typos (prefer implement).'
---

# Debug — Workflow

Systematic isolation and minimal fix.

Full coding rules in `instructions/*.instructions.md`. Key rules:

- **SQL**: never introduce concatenation while fixing — see `instructions/sql.instructions.md`
- **Exceptions**: no empty catch blocks; don't add new swallow points — see `instructions/java.instructions.md`
- **Resources**: connection leaks are a common root cause, not just style — see `instructions/java.instructions.md`
- **Hibernate**: session lifecycle issues cause subtle bugs — see `instructions/spring-hibernate.instructions.md`

## Problem Definition

Capture before touching code:
- Expected vs actual behavior
- Exact error message / stack trace (not paraphrased)
- Reproducible: always / sometimes / once
- Since when: recent change / always / unknown

## Hypothesis Approach

- List causes ranked by likelihood
- For each: what confirms, what refutes, effort to verify
- **Verify lowest-effort hypothesis first**
- Binary search on execution path: narrow until divergence is one line

## Root Cause Verification

Before fixing: does the cause explain ALL symptoms? Is this the ROOT cause or a symptom? Could the same cause affect other code?

## Fix Rules

- Fix only the root cause; do not refactor in a bugfix
- Smallest possible diff
- Search for same pattern elsewhere; log as separate findings

## Handoffs

- → `@implementer` — implement the fix after root cause confirmed
- ← `@implementer` — implementation reveals a deeper bug
- ← `performance` skill — performance issue turns out to be a bug
