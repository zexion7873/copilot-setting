---
name: plan
description: 'Use when user asks to plan a feature, design implementation steps, write a spec for upgrade / refactor / migration, or 寫實作計畫 / 規劃 / 拆 task / 升級計畫 / 遷移計畫 / 寫規格 / 定規格. Produces a structured Markdown spec under /plan/ with phases, atomic tasks, acceptance criteria, and risks. For non-trivial plans, suggest formalizing as an SDD via @doc-writer. Do NOT use for one-off bug fixes (just fix), architectural decisions (prefer adr skill), open-ended research (prefer spike skill), or full SDD creation (prefer sdd skill).'
---

# Plan — Workflow

Produce a self-contained implementation spec another developer (or AI) can execute without further clarification. **A plan is for work whose shape is known**; if the shape is still being explored, use `spike`.

## Phase 1 — Classify the Plan

Pick a purpose prefix; this drives the filename and the template focus.

| Prefix | When |
|---|---|
| `feature` | New user-facing capability |
| `refactor` | Restructure without behavior change |
| `upgrade` | Library / runtime / framework version bump |
| `data` | Schema change, backfill, migration |
| `infrastructure` | Pipeline, deploy, observability change |
| `architecture` | Multi-component restructuring |
| `process` | Workflow / team / convention change |
| `design` | UX or API contract design |

Filename: `[purpose]-[component]-[version].md` (kebab-case, integer version).
Examples: `upgrade-system-command-4.md`, `feature-auth-module-1.md`.

## Phase 2 — Gather Context

Before drafting, scan related code so the plan references real files, not guesses.

```bash
grep -rn "<key symbol>" --include="*.java" src/    # locate existing pattern
git log --oneline --all -- <relevant path>         # past changes, prior art
```

## Phase 3 — Draft Using Template

```md
---
goal: [Concise title]
version: [e.g., 1.0]
date_created: [YYYY-MM-DD]
last_updated: [YYYY-MM-DD]
owner: [Team / individual]
status: 'Planned' | 'In progress' | 'Completed' | 'On Hold' | 'Deprecated'
tags: [feature | upgrade | chore | architecture | migration | bug | ...]
---

# Introduction

[Short intro describing the plan and the goal it achieves.]

## 1. Requirements & Constraints

- **REQ-001**: Functional requirement
- **SEC-001**: Security requirement
- **CON-001**: Constraint
- **GUD-001**: Guideline
- **PAT-001**: Pattern to follow

## 2. Implementation Steps

### Phase 1

- GOAL-001: [What this phase achieves]

| Task | Description | Completed | Date |
|---|---|---|---|
| TASK-001 | ... | | |
| TASK-002 | ... | | |

### Phase 2

- GOAL-002: ...

## 3. Alternatives

- **ALT-001**: Alternative — rejected because ...

## 4. Dependencies

- **DEP-001**: External / internal dependency

## 5. Files

- **FILE-001**: Path — what changes here

## 6. Testing

- **TEST-001**: Test plan item

## 7. Risks & Assumptions

- **RISK-001**: Risk — mitigation
- **ASSUMPTION-001**: Assumption — verification

## 8. Related Specifications

- [Link to related spec / ADR / external doc]
- SDD: [Path to SDD if exists, or "To be created via @doc-writer"]
```

## Rules

- Each task atomic and individually verifiable — "TASK-001: rename `findUser` → `findActiveUserById` across `UserService` and 3 callers" not "TASK-001: clean up code"
- All identifiers use prefixes (`REQ-`, `TASK-`, `RISK-`, etc.) — enables cross-reference
- Phases independent unless a dependency is declared
- No placeholder text in the final output — every field populated
- Reference real files in the **Files** section — verify they exist
- For non-trivial features or cross-cutting changes, recommend formalizing the plan as an SDD via `@doc-writer` before implementation

## Handoffs

- → `implement` skill — once plan is approved, start execution
- → `sdd` skill / `@doc-writer` — when the plan needs a formal SDD before implementation
- → `adr` skill — if the plan exposes a decision worth recording
- ← `spike` skill — a spike's recommendation often becomes a plan
