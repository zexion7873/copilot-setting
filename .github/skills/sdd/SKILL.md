---
name: sdd
description: 'Use when a formal specification document is needed before implementation — defines scope, API contracts, data model, and acceptance criteria. Triggers on: write SDD, spec, specification, design document, 寫 SDD, 寫規格, 規格文件, 設計文件. Produces a structured SDD following the spec template. Do NOT use for lightweight plans (prefer plan), task breakdown (prefer tasks), or direct implementation (prefer implement).'
---

# SDD — Workflow

Spec-Driven Development document.

## Phase 1 — Gather Requirements

1. Extract functional and non-functional requirements from user input
2. Scan codebase for existing contracts, data models, and patterns
3. Identify integration points with existing modules

If requirements are unclear, hand off to `clarify-task` first.

## Phase 2 — Draft Specification

Fill the template below — every section must be concrete.

## Phase 3 — Self-Review

- [ ] Every requirement is testable (has clear pass/fail)
- [ ] API contracts include error responses
- [ ] Data model changes note migration/rollback
- [ ] No `TBD` or vague sections

## Output Template

Name file `sdd-[feature]-v[N].md`.

```md
---
title: <Feature name>
date: <YYYY-MM-DD>
author: <author>
status: 'Draft'
---

# <title>

## 1. Background

Why this change exists. Business context and motivation.

## 2. Requirements

- REQ-001: <testable requirement with pass/fail criteria>
- REQ-002: ...

## 3. Design

### Approach

High-level approach with rationale. Why this over alternatives.

### Alternatives Considered

- ALT-001: <approach> — rejected because <reason>

## 4. API Contract

| Method | Signature | Input | Output | Errors |
|---|---|---|---|---|
| ... | ... | ... | ... | ... |

## 5. Data Model

Entity/table changes. Migration script needed: yes/no. Rollback plan.

## 6. Error Handling

| Failure Mode | Detection | Recovery |
|---|---|---|
| ... | ... | ... |

## 7. Testing Strategy

- TEST-001: <what to verify> — <how> — maps to REQ-NNN

## 8. Out of Scope

What is explicitly NOT included in this work.
```

## Handoffs

- → `tasks` skill — to decompose SDD into atomic tasks
- → `@implementer` — when SDD is approved and ready
- → `clarify-task` skill — if gaps found during drafting
- ← `@planner` — default activation
