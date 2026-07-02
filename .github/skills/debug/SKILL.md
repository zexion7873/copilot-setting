---
name: debug
description: 'Use when user reports a bug, error, exception, or unexpected behavior needing root cause analysis and minimal fix. Triggers on: debug this, why does this fail, root-cause this, 除錯, 找 bug, 報錯了. Performs systematic isolation and minimal fix. Do NOT use for feature requests or known simple typos (prefer implement).'
---

# Debug — Workflow

Systematic isolation and minimal fix.

## Phase 0 — Load canonical rules

Before proposing a fix, open the instruction files for the layers you touch — glob auto-loading does not fire for files you read mid-task, and your training data defaults to modern Java/Spring (these files are the version lock): `instructions/java.instructions.md`, `instructions/spring-hibernate.instructions.md`, `instructions/sql.instructions.md`, `instructions/security.instructions.md` (a bug fix can regress a security control), `instructions/no-heredoc.instructions.md`.

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

List ≥ 3 candidate causes before ranking — never investigate the first hypothesis without listing alternatives. For each: what confirms it, what refutes it, effort to verify. **Verify lowest-effort hypothesis first.**

## Phase 4 — Isolate

Binary search on execution path: entry → failure point → check midpoint → narrow until divergence is one line.

## Phase 5 — Verify Root Cause

Verification gate (MUST answer before Phase 6):

1. Does this cause explain ALL reported symptoms? List each symptom + how this cause produces it.
2. Remove this cause hypothetically — would the bug disappear? If unsure, you haven't found root cause.
3. Is this the deepest cause, or a symptom of something upstream?

If any answer is "no" or "unsure" → return to Phase 3.

## Phase 6 — Propose Minimal Fix

- Specify the minimal fix for the root cause; do not propose refactoring in a bugfix
- Aim for the smallest possible diff
- Search for same pattern elsewhere; log as separate findings
- Hand off to `@implementer` for actual code changes

## Handoffs

- → `@implementer` — to implement the fix after root cause confirmed
