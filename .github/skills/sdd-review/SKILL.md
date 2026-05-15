---
name: sdd-review
description: 'Use when user needs an SDD specification reviewed before implementation — completeness, testability, feasibility, and clarity audit. Triggers on: review SDD, audit spec, is this SDD ready, check specification, 審查 SDD, 規格審查, SDD 可以了嗎, 看一下規格. Produces a structured review verdict. Do NOT use for code review (prefer code-review), implementation (prefer implement), or plan review (prefer plan).'
---

# SDD Review — Workflow

Pre-implementation specification review. Ensures the SDD is ready for implementation.

## Phase 1 — Read the SDD

Read the entire document. Note first impressions: is the scope clear? Are there obvious gaps?

## Phase 2 — Check Completeness

| Section | Check |
|---|---|
| Background | Problem and motivation clear? |
| Requirements | Each one testable (pass/fail criteria)? |
| Design | Approach justified? Alternatives considered? |
| API Contract | Signatures, inputs, outputs, error cases all present? |
| Data Model | Schema changes specified? Migration/rollback plan? |
| Error Handling | Failure modes and recovery defined? |
| Testing Strategy | Maps to requirements? |
| Out of Scope | Explicitly excludes what's NOT included? |

## Phase 3 — Check Feasibility

- Is this buildable with the current stack (Java 8, Spring Core, Hibernate 4.x)?
- Are there hidden dependencies or assumptions?
- Does the data model change require migration scripts?
- Are performance implications addressed for large datasets?

## Phase 4 — Verdict

```
## Verdict: READY / NEEDS REVISION / MAJOR GAPS

### Strengths
- ...

### Issues (by priority)
1. [MUST FIX] ...
2. [SHOULD FIX] ...
3. [NICE TO HAVE] ...

### Questions for Author
1. ...
```

## Handoffs

- → `@planner` — to revise the SDD based on review findings
- ← `@reviewer` — when SDD review mode is activated
