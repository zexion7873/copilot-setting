---
name: sdd
description: 'Use when a formal specification document is needed before implementation — defines scope, API contracts, data model, and acceptance criteria. Triggers on: write SDD, spec, specification, design document, 寫 SDD, 寫規格, 規格文件, 設計文件. Produces a structured SDD following the spec template. Do NOT use for lightweight plans (prefer plan), task breakdown (prefer tasks), or direct implementation (prefer implement).'
---

# SDD — Workflow

Spec-Driven Development document. Output format: `prompts/spec-template.prompt.md`.

## Phase 1 — Gather Requirements

1. Extract functional and non-functional requirements from user input
2. Scan codebase for existing contracts, data models, and patterns
3. Identify integration points with existing modules

If requirements are unclear, hand off to `clarify-task` first.

## Phase 2 — Draft Specification

Fill `prompts/spec-template.prompt.md`:
- **Background**: why this change exists
- **Requirements**: numbered, testable
- **Design**: approach with rationale
- **API Contract**: method signatures, input/output, error cases
- **Data Model**: entity changes, migration needs
- **Error Handling**: failure modes and recovery
- **Testing Strategy**: what to verify and how
- **Out of Scope**: explicit exclusions

## Phase 3 — Self-Review

Before presenting:
- [ ] Every requirement is testable (has clear pass/fail)
- [ ] API contracts include error responses
- [ ] Data model changes note migration/rollback
- [ ] No `TBD` or vague sections

## Handoffs

- → `tasks` skill — to decompose SDD into atomic tasks
- → `@implementer` — when SDD is approved and ready
- → `clarify-task` skill — if gaps found during drafting
- ← `@planner` — default activation
