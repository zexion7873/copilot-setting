---
name: plan
description: 'Use when user asks to plan a feature, design implementation phases, or estimate impact for an upgrade / refactor / migration. Triggers on: plan a feature, design implementation phases, estimate impact, upgrade plan, migration plan, implementation roadmap, 寫實作計畫, 規劃, 升級計畫, 遷移計畫, 估影響範圍, 設計實作步驟, 排階段. Produces a structured Markdown plan with phases, requirements, files, risks, and alternatives. Hands off to the tasks skill for atomic task breakdown. For non-trivial plans, suggest formalizing as an SDD via the sdd skill. Do NOT use for one-off bug fixes (just fix), architectural decisions (prefer adr skill), open-ended research (prefer spike skill), specification documents (prefer sdd skill), spec reviews (prefer sdd-review skill), or atomic task decomposition after a plan exists (prefer tasks skill). A plan produces a phased ROADMAP without formal acceptance criteria — if the user needs testable ACs or API contracts, redirect to sdd skill.'
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

Use the template in `prompts/plan-template.prompt.md`. All identifier prefixes (`REQ-`, `SEC-`, `CON-`, `GOAL-`, `ALT-`, `DEP-`, `FILE-`, `TEST-`, `RISK-`, `ASSUMPTION-`) must be used for cross-referencing from `tasks.md` and downstream artifacts.

## Rules

- Each phase has a single, verifiable goal — "GOAL-001: Replace `UserService` lookup with cached query" not "GOAL-001: improve performance"
- All identifiers use prefixes (`REQ-`, `RISK-`, `FILE-`, etc.) — enables cross-reference from tasks.md and downstream artifacts
- Phases independent unless a dependency is declared
- No placeholder text in the final output — every field populated
- Reference real files in the **Files** section — verify they exist
- For non-trivial features or cross-cutting changes, recommend formalizing the plan as an SDD via the `sdd` skill before implementation
- Do NOT generate atomic `TASK-` rows here — that is the `tasks` skill's job. Plans are the design layer; tasks are the execution layer.

## Handoffs

- → `tasks` skill — once the plan is approved, generate the atomic task list before implementation
- → `sdd` skill / `@planner` — when the plan needs a formal SDD before tasks / implementation
- → `adr` skill — if the plan exposes a decision worth recording
- ← `spike` skill — a spike's recommendation often becomes a plan
