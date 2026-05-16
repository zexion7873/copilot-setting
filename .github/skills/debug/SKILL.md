---
name: debug
description: 'Use when user reports a bug, error, exception, or unexpected behavior needing root cause analysis and minimal fix. Triggers on: debug, bug, exception, stack trace, root cause, why does this fail, NPE, 除錯, 找 bug, 報錯了, 為什麼會錯, 修 bug, 這裡怪怪的. Performs systematic isolation and minimal fix. Do NOT use for feature requests (prefer implement), performance tuning without a concrete error (prefer performance), or known simple typos (prefer implement).'
---

# Debug — Workflow

Systematic isolation and minimal fix.

Full coding rules in `instructions/*.instructions.md`. Key rules (fallback for agent chat):

- **Java 8**: no `var`, no `List.of()`, no records — checked exceptions must be handled or declared
- **Spring 3.2**: XML config + `<tx:advice>` only, no `@Transactional`, no Spring Boot
- **Hibernate 4.2**: `getCurrentSession()` only, `hbm.xml` mappings, no JPA annotations
- **SQL (JDBC)**: `PreparedStatement` with `?` — zero string concatenation
- **SQL (HQL)**: named parameters (`:param`) — never concatenate into query strings
- **Security**: `<c:out>` for all JSP output; `HttpOnly` + `Secure` cookie flags

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

## Phase 6 — Fix Minimally

- Fix only the root cause; do not refactor in a bugfix
- Smallest possible diff
- Search for same pattern elsewhere; log as separate findings

## Handoffs

- → `@implementer` — to implement the fix after root cause confirmed
- ← `@implementer` — when implementation reveals a deeper bug
- ← `performance` skill — when a performance issue turns out to be a bug
