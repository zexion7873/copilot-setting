---
agent: 'agent'
description: 'Dependency-ordered atomic task list scaffold with T### IDs and parallel markers. Pairs with skills/tasks/SKILL.md (workflow).'
---

# Tasks Template

One-shot scaffold for atomic task decomposition. Workflow: `skills/tasks/SKILL.md`. Upstream: a plan (`prompts/plan-template.prompt.md`) or SDD (`prompts/spec-template.prompt.md`).

## Usage

Invoke via `/tasks-template`. Source must be an approved plan or SDD.

## Template

```md
---
source: ${input:source:Path to plan or SDD}
date: ${input:date:YYYY-MM-DD}
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

- `[P]` — can run in parallel with other `[P]` tasks at the same dependency level
- `[US]` — requires user sign-off before proceeding

## Dependency Graph

```text
T001 → T002 → T004
T001 → T003 ──┘
```

## Coverage Matrix

| Requirement | Tasks |
|---|---|
| REQ-001 | T001, T002 |
| REQ-002 | T003 |
```

## Validation Checklist

- [ ] Every `${input:...}` placeholder replaced
- [ ] Every task maps to ≥1 requirement
- [ ] Every requirement maps to ≥1 task
- [ ] No circular dependencies
- [ ] Size estimates on every task
