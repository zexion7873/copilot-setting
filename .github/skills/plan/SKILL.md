---
name: plan
description: 'Use when user needs a phased implementation plan with requirements, file impact, risks, and alternatives before coding. Triggers on: plan, design approach, implementation strategy, how should we build, 規劃, 怎麼做, 幫我想方案, 寫計畫. Produces a structured plan document. Do NOT use for atomic task lists (prefer tasks) or unclear requirements (prefer clarify-task).'
---

# Plan — Workflow

Structured implementation plan.

## Phase 1 — Gather Context

1. Scan codebase for existing patterns relevant to the goal
2. Identify affected files and modules
3. Note constraints: tech stack (Java 8 / Maven / Spring 3.2 / Hibernate 4.2), backward compatibility, data migration needs

## Phase 2 — Classify Scope

| Scope | Definition | Plan depth |
|---|---|---|
| Small | 1–3 files, single module | Lightweight: goal + approach + files |
| Medium | 4–10 files, cross-module | Standard: full template |
| Large | 10+ files, schema change, or API change | Full template + API contract + data model + error handling |

## Phase 3 — Draft Plan

Fill the template below. Scale sections by scope:
- Small/Medium: sections 1–4 are sufficient
- Large: include sections 5–7 (API contract, data model, error handling)

Every section must be concrete — no `TBD` or vague placeholders.

## Phase 4 — Validate

- [ ] Every phase has one clear goal
- [ ] File list matches codebase scan results
- [ ] No `TBD` or placeholders left
- [ ] Large scope: API signatures have input/output types and error cases

## Output Template

```md
# <Goal — one sentence>

## 1. Scope

What's included. What's explicitly NOT included (prevents AI from over-engineering).

## 2. Affected Files & Patterns

- `path/to/File.java` — what changes
- Pattern to follow: `path/to/ExistingExample.java`

## 3. Approach

### Phase 1 — <Goal>

- What this phase achieves
- Components touched, order of work

### Phase 2 — <Goal>

- ...

## 4. Constraints & Risks

- Constraint: <e.g., Java 8, no Spring Boot, must use existing DAO pattern>
- Risk: <specific risk> — mitigation: <specific action>

## 5. API Contract (Large scope only)

| Method | Signature | Input | Output | Errors |
|---|---|---|---|---|
| ... | ... | ... | ... | ... |

## 6. Data Model (Large scope only)

Schema/entity changes. Migration needed: yes/no. Rollback approach.

## 7. Error Handling (Large scope only)

| Scenario | Handling |
|---|---|
| <input empty/null> | <what happens> |
| <record not found> | <what happens> |
| <concurrent modification> | <what happens> |

## Verification

- [ ] <concrete, pass/fail check>
- [ ] <concrete, pass/fail check>
```

## Handoffs

- → `tasks` skill — to break plan into atomic task list
- → `clarify-task` skill — if gaps found during planning
- ← `@planner` — default activation
