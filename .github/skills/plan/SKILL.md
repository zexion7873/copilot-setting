---
name: plan
description: 'Use when user needs a phased implementation plan with requirements, file impact, risks, and alternatives before coding. Triggers on: plan, design approach, implementation strategy, how should we build, 規劃, 怎麼做, 幫我想方案, 寫計畫. Produces a structured plan document. Do NOT use for formal specifications (prefer sdd), atomic task lists (prefer tasks), or unclear requirements (prefer clarify-task).'
---

# Plan — Workflow

Structured implementation plan. Output format: `prompts/plan-template.prompt.md`.

## What to Gather

- Existing patterns relevant to the goal (scan codebase first)
- Affected files and modules
- Constraints: Java 8, Maven, Spring 3.2, Hibernate 4.2, backward compatibility, migration needs

## Scope Calibration

| Scope | Files | Plan depth |
|---|---|---|
| Small | 1–3 | Lightweight: goal + approach + files |
| Medium | 4–10 | Standard: full template |
| Large | 10+ or schema change | Full template + risk analysis + alternatives |

## What Makes a Good Plan

- Every requirement has a traceable `REQ-NNN` / `CON-NNN` identifier
- Every phase has one measurable goal
- File list matches actual codebase paths
- Risks have specific mitigations, not "might be hard"
- At least one rejected alternative with reason
- No `TBD` or placeholders

## Handoffs

- → `tasks` skill — break plan into atomic task list
- → `sdd` skill — formal spec needed before implementation
- → `clarify-task` skill — gaps found during planning
- ← `@planner` — default activation
