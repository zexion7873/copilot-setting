---
name: tasks
description: 'Use when a plan or SDD needs to be broken into dependency-ordered atomic tasks for implementation. Triggers on: break down tasks, task list, decompose, create tasks, 拆任務, 拆工作, 任務拆解, 列出步驟. Produces a T###-formatted task list with dependency ordering and parallel markers. Do NOT use for creating plans (prefer plan), writing specs (prefer sdd), or direct implementation (prefer implement).'
---

# Tasks — Workflow

Atomic task decomposition. Output format: `prompts/tasks-template.prompt.md`.

## Input

An approved plan or SDD. Extract: phases/goals, file list, dependencies, constraints.

## What Makes a Good Task

- **One action**: single file change or closely related set
- **Verifiable**: clear done-when condition
- **Estimated**: S (< 30 min) / M (30–120 min) / L (> 2 hours)
- **Traceable**: maps to ≥1 requirement from source

## Ordering & Markers

- `T001`, `T002`, ... — sequential numbering
- Dependency graph: which task blocks which
- `[P]` — parallel-safe with other `[P]` tasks at same level
- `[US]` — requires user sign-off

## Quality Bar

- Every task maps to ≥1 requirement
- Every requirement maps to ≥1 task
- No circular dependencies
- No orphan tasks

## Handoffs

- → `@implementer` — start executing task list
- ← `plan` skill — after plan approved
- ← `sdd` skill — after SDD approved
