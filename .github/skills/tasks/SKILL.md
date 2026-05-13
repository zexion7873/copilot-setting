---
name: tasks
description: 'Use when user asks to break work into atomic, executable tasks AFTER a plan or SDD already exists. Triggers on: 拆 task, 拆任務, 拆步驟, 列出任務, 產生 tasks 列表, 排執行順序, break down tasks, generate tasks list, decompose work, sequence implementation steps, generate tasks.md. Produces a dependency-ordered tasks.md with phase grouping (Setup → Foundational → User Stories → Polish), T### IDs, parallel markers, and a coverage map back to spec IDs. Do NOT use when no plan or SDD exists yet (prefer plan or sdd skill first), for one-off bug fixes, for ambiguous scope (prefer clarify-task), or to redesign the plan itself (prefer plan skill).'
---

# Tasks — Workflow

Decompose an approved plan or SDD into atomic, dependency-ordered tasks ready for execution. This skill activates AFTER plan / SDD are approved. It does NOT design — it only sequences. If the design is wrong, hand back to `plan` or `sdd`, do not patch it here.

## Phase 1 — Prerequisite Gate

Verify the design layer exists before generating tasks. Inspired by Spec-Driven Development's prerequisite-gating pattern (Spec Kit prior art) — no design, no tasks.

- Plan exists at `/plan/*.md` OR SDD exists at `/docs/spec/*.md` OR user supplies an explicit path
- If neither exists: STOP. Redirect user to `plan` or `sdd` skill first.
- If plan exists but lacks `## 5. Files` section: WARN. Ask user whether to proceed without verified file paths.
- If SDD exists but `## 4. Acceptance Criteria` is empty: WARN. Tasks without ACs cannot be traced.

## Phase 2 — Inventory Inputs

Read in this order, accumulating constraints:

1. **Constitution** (if exists at `docs/constitution.md`) — non-negotiable testing / quality rules (e.g., TDD mandatory, coverage thresholds)
2. **SDD** (if exists) — `FR-` / `AC-` / `SC-`, files to change (§7), schema changes (§3.3)
3. **Plan** — phases, `REQ-` / `CON-` / `PAT-` / `FILE-` identifiers
4. **Existing tests in workspace** — detect whether TDD enforcement is already established

If both plan and SDD exist, SDD wins on requirements, plan wins on phasing.

## Phase 3 — Generate Tasks

Use this canonical structure. Output is a complete `tasks.md` file, written next to the source plan or SDD.

```md
# Tasks: [Feature Title]

**Source**: [absolute path to plan.md or spec.md]
**Generated**: [YYYY-MM-DD]

## Format

`- [ ] [ID] [P?] [Story?] Description (file path)`

- `[P]` — parallelizable: different files, no dependency on incomplete tasks
- `[Story]` — maps to spec user stories (US1, US2…) or plan REQ-IDs
- Description ends with the exact file path the task touches

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Create project structure per plan §5
- [ ] T002 [P] Configure linting / formatter

## Phase 2: Foundational (Blocking Prerequisites)

- [ ] T003 Setup migration framework
- [ ] T004 [P] Implement base entities all stories depend on

## Phase 3: User Story 1 — [Title] (Priority: P1) 🎯 MVP

**Goal**: [What this story delivers in user terms]
**Independent Test**: [How to verify this story works on its own]

### Tests for US1 (write FIRST, ensure they FAIL)

- [ ] T010 [P] [US1] Contract test for `OrderService.findByCustomerId` in `src/test/java/.../OrderServiceTest.java`

### Implementation for US1

- [ ] T011 [P] [US1] Implement `Order` entity in `src/main/java/.../Order.java`
- [ ] T012 [US1] Wire `Order` to `OrderService` (depends on T011)

## Phase 4: Polish & Cross-Cutting

- [ ] T030 Add observability per constitution §III

## Dependencies & Execution Order

- Setup → Foundational → User Stories (P1 → P2 → P3) → Polish
- Within story: failing tests → implementation → integration
- Tasks touching the same file MUST run sequentially regardless of `[P]`

## Coverage Map

| Spec ID | Tasks |
|---|---|
| AC-001 | T010, T011 |
| AC-002 | T012 |
```

## Phase 4 — Validate

Before presenting, verify:

- Every spec `AC-` (or plan `REQ-`) appears in the coverage map at least once
- Every task has a real file path OR is explicitly infrastructure setup
- Test tasks precede their corresponding implementation tasks (TDD default)
- No phase has circular dependencies
- `[P]` markers are correct — no parallel tag on tasks touching the same file
- No placeholder text — every bracket is replaced with concrete content

## Rules

- Task IDs: `T001` upward, sequential, no gaps
- One task = one verifiable outcome — "T015 [US1] Implement `OrderService.findByCustomerId`" not "T015 clean up service layer"
- File paths MUST be real OR be declared in plan §5 / SDD §7
- Tests-first ordering is the default — override only on explicit user request, then mark `[NO-TDD]` on affected tasks
- Output is a complete `tasks.md` file, not a fragment
- Do NOT redesign the plan during task generation — if the plan is wrong, hand back to `plan` skill
- Setup and Foundational tasks have NO `[Story]` label; only user-story phase tasks do

## Handoffs

- → `implement` skill / `@implementer` — once tasks are generated, start execution
- → `sdd-compliance` skill — after implementation, verify spec coverage against this task list
- ← `plan` skill — plan hands off task generation here
- ← `sdd` skill — SDD hands off task generation here
