---
agent: 'agent'
description: 'Dependency-ordered tasks.md template with T### IDs, [P] parallel markers, [US] story labels, and TDD-first ordering. Aligns with GitHub Spec Kit canonical format. Pairs with skills/tasks/SKILL.md (workflow / prerequisite gate / validation).'
---

# Tasks Template

One-shot scaffold for `tasks.md`. Workflow (prerequisite gate, input inventory, validation) lives in `skills/tasks/SKILL.md`. This prompt only defines the OUTPUT FORMAT, aligned with GitHub Spec Kit canonical structure.

## Usage

Invoke via `/tasks-template`. Requires an approved plan or SDD already in the workspace. If none exists, run the `plan` or `sdd` skill first — this template will fail validation without an upstream design artifact.

## Format

`- [ ] [ID] [P?] [Story?] Description (file path)`

- `[P]` — parallelizable: different files, no dependency on incomplete tasks
- `[Story]` — maps to spec user stories (US1, US2, US3…) or plan REQ-IDs
- Description ends with the exact file path the task touches

## Template

```md
# Tasks: ${input:featureTitle}

**Source**: ${input:sourcePlan:absolute path to plan.md or spec.md}
**Generated**: ${input:date:YYYY-MM-DD}

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Create project structure per source §5
- [ ] T002 [P] Configure linting / formatter

## Phase 2: Foundational (Blocking Prerequisites)

- [ ] T003 Setup migration framework
- [ ] T004 [P] Implement base entities all stories depend on

## Phase 3: User Story 1 — ${input:us1Title} (Priority: P1) 🎯 MVP

**Goal**: [What this story delivers in user terms]
**Independent Test**: [How to verify this story works on its own]

### Tests for US1 (write FIRST, ensure they FAIL)

- [ ] T010 [P] [US1] Contract test for `Service.method` in `src/test/java/.../Test.java`
- [ ] T011 [P] [US1] Integration test for user journey in `src/test/java/.../IT.java`

### Implementation for US1

- [ ] T012 [P] [US1] Implement `Entity` in `src/main/java/.../Entity.java`
- [ ] T013 [US1] Wire `Entity` to `Service` (depends on T012)
- [ ] T014 [US1] Add validation and error handling
- [ ] T015 [US1] Add logging per `instructions/logging.instructions.md`

## Phase N: User Story 2 — [Title] (Priority: P2)

[Same structure as Phase 3]

## Phase Final: Polish & Cross-Cutting

- [ ] T030 Add observability per `docs/constitution.md` §III
- [ ] T031 [P] Update Javadoc per `instructions/javadoc.instructions.md`

## Dependencies & Execution Order

- Setup → Foundational → User Stories (P1 → P2 → P3) → Polish
- Within story: failing tests → implementation → integration
- Tasks touching the same file MUST run sequentially regardless of `[P]`

## Coverage Map

| Spec ID | Tasks |
|---|---|
| AC-001 | T010, T012 |
| AC-002 | T011, T013 |
```

## Validation Checklist

- [ ] Every `${input:...}` placeholder replaced
- [ ] Task IDs sequential from `T001`, no gaps
- [ ] Every spec `AC-` appears in the Coverage Map at least once
- [ ] Test tasks precede their corresponding implementation tasks (TDD default)
- [ ] No `[P]` marker on tasks touching the same file
- [ ] Setup and Foundational phases have NO `[Story]` label
- [ ] Every user-story phase task HAS a `[USx]` label
- [ ] Every task description ends with a concrete file path OR is explicit infrastructure setup
