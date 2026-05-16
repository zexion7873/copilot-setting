---
name: sdd
description: 'Use when a formal specification document is needed before implementation — defines scope, API contracts, data model, and acceptance criteria. Triggers on: write SDD, spec, specification, design document, 寫 SDD, 寫規格, 規格文件, 設計文件. Produces a structured SDD following the spec template. Do NOT use for lightweight plans (prefer plan), task breakdown (prefer tasks), or direct implementation (prefer implement).'
---

# SDD — Workflow

Spec-Driven Development document. Output format: `prompts/spec-template.prompt.md`.

## What to Include

Fill `prompts/spec-template.prompt.md` — every section must be concrete:

- **Background**: why this change exists
- **Requirements**: numbered, each with pass/fail criteria
- **Design**: approach with rationale and rejected alternatives
- **API Contract**: method signatures, input/output, error cases
- **Data Model**: entity changes, migration needs, rollback plan
- **Error Handling**: failure modes and recovery
- **Testing Strategy**: what to verify, mapped to requirements
- **Out of Scope**: explicit exclusions

## Quality Bar

- Every requirement is testable
- API contracts include error responses
- Data model changes note migration/rollback
- No `TBD` or vague sections

If requirements are unclear, hand off to `clarify-task` first.

## Handoffs

- → `tasks` skill — decompose SDD into atomic tasks
- → `@implementer` — SDD approved and ready
- → `clarify-task` skill — gaps found during drafting
- ← `@planner` — default activation
