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
| Large | 10+ files, schema change, or API change | Full template + risk analysis + alternatives |

## Phase 3 — Draft Plan

Fill the template below. Every section must be concrete:
- Requirements: traceable `REQ-NNN` / `CON-NNN` identifiers
- Approach: phased, each phase has a measurable goal
- Files: real paths from the codebase scan
- Risks: with specific mitigation, not generic "might be hard"

## Phase 4 — Validate

- [ ] Every phase has one clear goal
- [ ] File list matches codebase scan results
- [ ] No `TBD` or placeholders left
- [ ] Alternatives section has at least one rejected option with reason

## Output Template

Name file `[purpose]-[component]-v[N].md`.

```md
---
goal: <Concise plan title>
date: <YYYY-MM-DD>
owner: <owner>
status: 'Planned'
---

# <goal>

## 1. Requirements & Constraints

- REQ-001: <functional requirement>
- CON-001: <constraint — e.g., Java 8, no Spring Boot>
- PAT-001: <existing pattern to follow>

## 2. Implementation Approach

### Phase 1 — <Goal>

- What this phase achieves
- Approach: components touched, order of work

### Phase 2 — <Goal>

- ...

## 3. Files

- FILE-001: `path/to/File.java` — what changes

## 4. Risks & Alternatives

- RISK-001: <risk> — mitigation: <specific action>
- ALT-001: <alternative considered> — rejected because <reason>

## 5. Dependencies

- DEP-001: <external or internal dependency>
```

## Handoffs

- → `tasks` skill — to break plan into atomic task list
- → `clarify-task` skill — if gaps found during planning
- ← `clarify-task` skill — when ambiguity resolved and ready to plan
- ← `@planner` — default activation
