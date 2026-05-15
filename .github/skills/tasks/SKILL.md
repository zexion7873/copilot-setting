---
name: tasks
description: 'Use when a plan or SDD needs to be broken into dependency-ordered atomic tasks for implementation. Triggers on: break down tasks, task list, decompose, create tasks, 拆任務, 拆工作, 任務拆解, 列出步驟. Produces a T###-formatted task list with dependency ordering and parallel markers. Do NOT use for creating plans (prefer plan), writing specs (prefer sdd), or direct implementation (prefer implement).'
---

# Tasks — Workflow

Atomic task decomposition. Output format: `prompts/tasks-template.prompt.md`.

## Phase 1 — Parse Source

Read the plan or SDD that was approved. Extract:
- Implementation phases / goals
- File list with expected changes
- Dependencies between components
- Constraints that affect ordering

## Phase 2 — Decompose

Break each phase into atomic tasks. Each task must be:
- **One action**: a single file change or a closely related set of changes
- **Verifiable**: has a clear done-when condition
- **Estimated**: S (< 30 min) / M (30–120 min) / L (> 2 hours)

## Phase 3 — Order by Dependency

1. Build dependency graph (T001 must complete before T002)
2. Mark parallel-safe tasks with `[P]`
3. Mark tasks requiring user sign-off with `[US]`
4. Number sequentially: `T001`, `T002`, ...

## Phase 4 — Format Output

Fill `prompts/tasks-template.prompt.md`:
- Dependency table: which task blocks which
- Coverage matrix: every requirement from source mapped to ≥1 task
- No orphan tasks (every task traces to a requirement)

## Handoffs

- → `@implementer` — to start executing task list
- ← `plan` skill — after plan is approved
- ← `sdd` skill — after SDD is approved
