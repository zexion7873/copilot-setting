---
name: tasks
description: 'Use when a plan needs to be broken into dependency-ordered atomic tasks for implementation. Triggers on: break down tasks, task list, decompose, create tasks, 拆任務, 拆工作, 任務拆解, 列出步驟. Produces a T###-formatted task list with dependency ordering and parallel markers. Do NOT use for creating plans (prefer plan) or direct implementation (prefer implement).'
---

# Tasks — Workflow

Atomic task decomposition from an approved plan.

## Phase 1 — Parse Source

Locate the approved plan in `docs/plans/` (the `plan` skill writes there). If the user named a plan, read that file. If exactly one plan exists, use it. If none exists or the source is ambiguous, **stop and ask** — do not invent a task list from scratch; redirect to the `plan` skill when no plan exists yet.

From the plan, extract: phases/goals, file list, dependencies, constraints. Record the plan's path in the `source:` field of the output.

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

Write the task breakdown to `docs/plans/<plan-basename>.tasks.md` beside the source plan, so the `source:` frontmatter link resolves as a relative sibling path.

```md
---
source: <Path to plan>
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
