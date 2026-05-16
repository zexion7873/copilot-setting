---
name: tasks
description: 'Use when a plan or SDD needs to be broken into dependency-ordered atomic tasks for implementation. Triggers on: break down tasks, task list, decompose, create tasks, 拆任務, 拆工作, 任務拆解, 列出步驟. Produces a T###-formatted task list with dependency ordering and parallel markers. Do NOT use for creating plans (prefer plan), writing specs (prefer sdd), or direct implementation (prefer implement).'
---

# Tasks — Workflow

Atomic task decomposition from an approved plan or SDD.

## Phase 1 — Parse Source

Read the plan or SDD. Extract: phases/goals, file list, dependencies, constraints.

## Phase 2 — Decompose

Break each phase into atomic tasks. Each task must be:
- **One action**: a single file change or closely related set
- **Verifiable**: clear done-when condition
- **Estimated**: S (< 30 min) / M (30–120 min) / L (> 2 hours)

## Phase 3 — Order by Dependency

1. Build dependency graph (T001 must complete before T002)
2. Mark parallel-safe tasks with `[P]`
3. Mark tasks requiring user sign-off with `[US]`
4. Number sequentially: `T001`, `T002`, ...

## Phase 4 — Validate

- [ ] Every task maps to ≥1 requirement
- [ ] Every requirement maps to ≥1 task
- [ ] No circular dependencies
- [ ] Size estimates on every task

## Output Template

```md
---
source: <Path to plan or SDD>
date: <YYYY-MM-DD>
---

# Task Breakdown

## Tasks

| ID | Task | Size | Depends On | Markers | Done When |
|---|---|---|---|---|---|
| T001 | <action on specific file/module> | S/M/L | — | | <verifiable condition> |
| T002 | ... | S | T001 | | ... |
| T003 | ... | M | T001 | [P] | ... |
| T004 | ... | S | T002, T003 | [US] | ... |

### Markers

- `[P]` — parallel-safe at same dependency level
- `[US]` — requires user sign-off

## Dependency Graph

T001 → T002 → T004
T001 → T003 ──┘

## Coverage Matrix

| Requirement | Tasks |
|---|---|
| REQ-001 | T001, T002 |
| REQ-002 | T003 |
```

## Handoffs

- → `@implementer` — to start executing task list
- ← `plan` skill — after plan is approved
- ← `sdd` skill — after SDD is approved
