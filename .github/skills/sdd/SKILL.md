---
name: sdd
description: 'Use when user asks to write an SDD, create a spec document, define a specification, or adopt spec-driven development. Triggers on: write SDD, create spec document, write specification, define spec, Spec-Driven Development, spec before code, 寫 SDD, 寫規格, 定規格, 寫規格文件, 定義規格, 規格驅動開發, 先定規格再實作. Produces a formal SDD covering design, API specs, schema changes, and acceptance criteria. Do NOT use for implementation phasing without spec depth (prefer plan skill), atomic task breakdowns (prefer tasks skill), quick bug fixes, general documentation, architectural decision records (prefer adr skill), or reviewing an existing SDD (prefer sdd-review skill).'
---

# SDD — Workflow

Create a formal Spec-Driven Development (SDD) document BEFORE implementation begins. The SDD is the contract between planning and coding — implementation must comply with it. Output format defined in `prompts/spec-template.prompt.md`.

## Phase 0 — Amendment Gate

Before drafting, detect whether an SDD already exists covering this scope:

```bash
ls docs/spec/*.md 2>/dev/null
find . -name "*.md" -path "*spec*" -not -path "*/target/*" -not -path "*/node_modules/*"
grep -rl "## 4. Acceptance Criteria\|## 9. Changelog" --include="*.md" . 2>/dev/null
```

If a matching SDD is found → **enter amendment mode**. If none → continue to Phase 1 (new SDD mode).

### Amendment Mode

When amending an existing SDD, follow these 6 steps in order:

1. **Read the existing SDD completely** — including §9 Changelog if present, to understand prior amendments
2. **Mark changed sections** — use diff-style markers in the draft (e.g., `[MODIFIED-AC-3]`, `[ADDED-AC-7]`, `[REMOVED-AC-5]`, `[MODIFIED-FILE-2]`)
3. **Require rationale** — every modified / added / removed item MUST have a one-sentence justification next to it
4. **Bump semver** — apply the rules below
5. **Produce Sync Impact Report** — list downstream artifacts that need update (see format below)
6. **Hand off downstream** — re-scope tasks, refactor code, invalidate compliance matrix (see Handoffs section)

### Semver Bump Rules

| Change type | Bump |
|---|---|
| Removed AC, broken API contract, incompatible schema change | **MAJOR** |
| New AC, new endpoint, backward-compatible schema change | **MINOR** |
| Clarification, typo, example added, wording polish | **PATCH** |

### Sync Impact Report

Insert at the top of the amended SDD as an HTML comment (same pattern as the `constitution` skill):

```html
<!--
Sync Impact Report:
Version: X.Y.Z → X'.Y'.Z'
Modified ACs: [AC-3 old → new] | (none)
Added FRs / ACs: ...
Removed sections: ...
Tasks requiring updates: ✅ T024 (re-scope) | ⚠ T031 (pending review)
Tests requiring updates: ...
Code requiring re-implementation: ...
Compliance matrix: invalidated — re-run sdd-compliance after re-implementation
-->
```

If amendment mode is active, skip Phase 1's readiness checks (already validated when the original SDD was approved). Proceed to Phase 2 with the EXISTING SDD as the base, applying changes incrementally rather than rewriting from scratch.

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

Use the template in `prompts/spec-template.prompt.md`. Every section (§1–§9) must be populated — no placeholders.

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

After **new SDD**:

- → `tasks` skill — once SDD is approved, decompose into atomic tasks before implementation
- → `@implementer` / `implement` skill — start coding (after tasks list is generated)
- → `sdd-compliance` skill — after implementation, verify code delivers what this SDD specified
- → `sdd-review` skill — for spec quality review before tasks / implementation
- ← `plan` skill — a plan often becomes the foundation for an SDD
- ← `@planner` — planner may suggest creating an SDD for complex features

After **amendment** (Phase 0 amendment mode):

- → `tasks` skill — re-scope affected T### IDs based on the Sync Impact Report
- → `@implementer` — if amendment changes API contracts or schema, refactor accordingly with the new contract as source of truth
- → `sdd-compliance` skill — invalidate the previous compliance matrix; re-run after re-implementation to verify the amended ACs are covered
