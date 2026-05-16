---
name: plan
description: 'Use when user needs a phased implementation plan with requirements, file impact, risks, and alternatives before coding. Triggers on: plan, design approach, implementation strategy, how should we build, 規劃, 怎麼做, 幫我想方案, 寫計畫. Produces a structured plan document. Do NOT use for formal specifications (prefer sdd), atomic task lists (prefer tasks), or unclear requirements (prefer clarify-task).'
---

# Plan — Workflow

Structured implementation plan. Output format: `prompts/plan-template.prompt.md`.

## Phase 1 — Gather Context

1. Scan codebase for existing patterns relevant to the goal
2. Identify affected files and modules
3. Note constraints: tech stack (Java 8 / Maven / Spring Core / Hibernate 4.x), backward compatibility, data migration needs

## Phase 2 — Classify Scope

| Scope | Definition | Plan depth |
|---|---|---|
| Small | 1–3 files, single module | Lightweight: goal + approach + files |
| Medium | 4–10 files, cross-module | Standard: full template |
| Large | 10+ files, schema change, or API change | Full template + risk analysis + alternatives |

## Phase 3 — Draft Plan

Fill `prompts/plan-template.prompt.md`. Every section must be concrete:
- Requirements: traceable `REQ-NNN` / `CON-NNN` identifiers
- Approach: phased, each phase has a measurable goal
- Files: real paths from the codebase scan
- Risks: with specific mitigation, not generic "might be hard"

## Phase 4 — Validate

- [ ] Every phase has one clear goal
- [ ] File list matches codebase scan results
- [ ] No `TBD` or placeholders left
- [ ] Alternatives section has at least one rejected option with reason

## Handoffs

- → `tasks` skill — to break plan into atomic task list
- → `sdd` skill — if a formal spec is needed before implementation
- → `clarify-task` skill — if gaps found during planning
- ← `@planner` — default activation
