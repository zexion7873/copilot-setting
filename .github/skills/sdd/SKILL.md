---
name: sdd
description: 'Use when user asks to write an SDD, create a spec document, define a specification, or adopt spec-driven development. Triggers on: write SDD, create spec document, write specification, define spec, Spec-Driven Development, spec before code, 寫 SDD, 寫規格, 定規格, 寫規格文件, 定義規格, 規格驅動開發, 先定規格再實作. Produces a formal SDD covering design, API specs, schema changes, and acceptance criteria. Do NOT use for implementation phasing without spec depth (prefer plan skill), atomic task breakdowns (prefer tasks skill), quick bug fixes, general documentation, architectural decision records (prefer adr skill), or reviewing an existing SDD (prefer sdd-review skill).'
---

# SDD — Workflow

Create a formal Spec-Driven Development (SDD) document BEFORE implementation begins. The SDD is the contract between planning and coding — implementation must comply with it. Output format defined in `prompts/spec-template.prompt.md`.

## Phase 1 — Assess Readiness

Before drafting, verify you have enough context:

- **Existing plan?** — check for a `/plan/` document. If one exists, use it as the foundation.
- **Requirements clear?** — if scope is ambiguous, use `clarify-task` skill first.
- **Architecture decided?** — if a design decision is open, use `adr` skill first.

If none of the above exist and the request is non-trivial, gather context:

```bash
grep -rn "<key symbol>" --include="*.java" src/    # existing patterns
git log --oneline -20 -- <relevant path>            # recent changes
```

If the spec involves external libraries or third-party API contracts, use Context7 to fetch authoritative docs so §3.2 API Specification and §3.4 Business Rules reference accurate signatures and behaviors. If Context7 is not available, fall back to web search or proceed with available context.

## Phase 2 — Draft SDD

Use the template in `prompts/spec-template.prompt.md`. Every section (§1–§8) must be populated — no placeholders.

## Phase 3 — Validate

Before presenting, verify:

- Every acceptance criterion is testable — no subjective language ("should be fast")
- File paths reference real files in the codebase
- Schema changes include rollback strategy
- No section left as placeholder

## Rules

- The SDD is the single source of truth for implementation scope — anything not in the SDD is out of scope
- Use Mermaid diagrams for any multi-component interaction
- Acceptance criteria drive test design — write them as if a test engineer will read them
- If the SDD reveals complexity beyond the original estimate, flag it explicitly

## Handoffs

- → `tasks` skill — once SDD is approved, decompose into atomic tasks before implementation
- → `@implementer` / `implement` skill — start coding (after tasks list is generated)
- → `sdd-review` skill — for spec quality review before tasks / implementation
- ← `plan` skill — a plan often becomes the foundation for an SDD
- ← `@planner` — planner may suggest creating an SDD for complex features
