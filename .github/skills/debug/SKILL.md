---
name: debug
description: 'Use when user reports a bug, error, exception, or unexpected behavior needing root cause analysis and minimal fix. Triggers on: debug this, why does this fail, root-cause this, 除錯, 找 bug. Performs systematic isolation and minimal fix. Do NOT use for feature requests (prefer implement) or known simple typos (prefer implement).'
---

# Debug — Workflow

Systematic isolation and minimal fix.

## Phase 0 — Load canonical rules

**MANDATORY pre-load gate — do NOT propose a fix (Phase 6) until you have opened the stack instruction modules for the layers you touch.** Your training data defaults to the newest idioms; the files under `instructions/` are this project's stack modules — its version lock and house rules. List that directory, then open every module covering the layers this bug touches. Always include the security module — a bug fix can regress a security control (XSS, IDOR, injection). The negative lists in the agent body are a floor, not the full rules.

Read-back receipt (self-check, not machine-enforced): before leaving this step, NAME each module you opened and QUOTE the single most load-bearing rule from each that applies to this change — a generic restatement you could have written from memory means you skipped the file, so open it for real.

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
