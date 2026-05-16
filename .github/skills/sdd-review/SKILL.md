---
name: sdd-review
description: 'Use when user needs an SDD specification reviewed before implementation — completeness, testability, feasibility, and clarity audit. Triggers on: review SDD, audit spec, is this SDD ready, check specification, 審查 SDD, 規格審查, SDD 可以了嗎, 看一下規格. Produces a structured review verdict. Do NOT use for code review (prefer code-review), implementation (prefer implement), or plan review (prefer plan).'
---

# SDD Review — Workflow

Pre-implementation specification review.

## Completeness Checklist

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

## Feasibility

- Buildable with current stack (Java 8, Spring 3.2, Hibernate 4.2)?
- Hidden dependencies or assumptions?
- Data model change requires migration scripts?
- Performance implications for large datasets?

## Output

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

- → `@planner` — revise SDD based on findings
- ← `@reviewer` — SDD review mode activated
