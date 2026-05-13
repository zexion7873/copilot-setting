---
name: plan
description: 'Use when user asks to plan a feature, design implementation phases, or estimate impact for an upgrade / refactor / migration. Also triggers on: 寫實作計畫, 規劃, 升級計畫, 遷移計畫, 估影響範圍, 設計實作步驟. Produces a structured Markdown plan with phases, requirements, files, risks, and alternatives. Hands off to the tasks skill for atomic task breakdown. For non-trivial plans, suggest formalizing as an SDD via @doc-writer. Do NOT use for one-off bug fixes (just fix), architectural decisions (prefer adr skill), open-ended research (prefer spike skill), specification documents (prefer sdd skill), spec reviews (prefer sdd-review skill), or atomic task decomposition after a plan exists (prefer tasks skill). A plan produces a phased ROADMAP without formal acceptance criteria — if the user needs testable ACs or API contracts, redirect to sdd skill.'
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

## 2. Implementation Approach

High-level phasing only. Each phase has a goal and a brief description of what it accomplishes. Atomic task breakdown (T### IDs, dependencies, parallel markers) is generated separately by the `tasks` skill after this plan is approved.

### Phase 1

- GOAL-001: [What this phase achieves]
- Approach: [How — components touched, order of attack, no per-task detail]

### Phase 2

- GOAL-002: ...
- Approach: ...

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

- Each phase has a single, verifiable goal — "GOAL-001: Replace `UserService` lookup with cached query" not "GOAL-001: improve performance"
- All identifiers use prefixes (`REQ-`, `RISK-`, `FILE-`, etc.) — enables cross-reference from tasks.md and downstream artifacts
- Phases independent unless a dependency is declared
- No placeholder text in the final output — every field populated
- Reference real files in the **Files** section — verify they exist
- For non-trivial features or cross-cutting changes, recommend formalizing the plan as an SDD via `@doc-writer` before implementation
- Do NOT generate atomic `TASK-` rows here — that is the `tasks` skill's job. Plans are the design layer; tasks are the execution layer.

## Handoffs

- → `tasks` skill — once the plan is approved, generate the atomic task list before implementation
- → `sdd` skill / `@doc-writer` — when the plan needs a formal SDD before tasks / implementation
- → `adr` skill — if the plan exposes a decision worth recording
- ← `spike` skill — a spike's recommendation often becomes a plan
