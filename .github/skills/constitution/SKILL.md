---
name: constitution
description: 'Use when user asks to define or update the project constitution — the non-negotiable principles and governance rules that supersede other practices. Triggers on: 寫 constitution, 定義原則, 訂專案原則, 更新治理規則, 修改 constitution, write constitution, define core principles, update governance, amend constitution, project principles. Produces or updates docs/constitution.md with non-negotiable principles, governance rules, and a Sync Impact Report. Do NOT use for coding standards or file-type rules (prefer creating an instructions file), for transient policies (constitution is for stable rules only), or for general documentation.'
---

# Constitution — Workflow

Stable, non-negotiable project rules. Supersedes all other practices when in conflict. Changes infrequently — if you find yourself updating this monthly, the rules belong elsewhere.

## Phase 1 — Scope Gate

Before writing, confirm the rule belongs in constitution vs elsewhere. This gate is what keeps constitution from bloating into a second instructions folder.

| Belongs in... | Examples |
|---|---|
| `docs/constitution.md` | "All financial calculations MUST use BigDecimal", "TDD is non-negotiable", "No hand-rolled crypto" |
| `instructions/*.instructions.md` | "Use `<c:out>` in JSP", "Log via SLF4J parameterized messages", "ATX headings only" |

| commit-time decision | "Rename `getCwd` to `getCurrentWorkingDirectory` across 8 callers" |

If the rule is feature-scoped, file-type specific, transient, or just a coding convention: REDIRECT. Do not put it in constitution.

## Phase 2 — Load or Initialize

- If `docs/constitution.md` exists: read fully, identify amendment scope and affected sections
- If not: scaffold from the template (see Phase 3) with version `1.0.0`, ratification date today

## Phase 3 — Draft or Amend

Required structure:

```md
<!--
Sync Impact Report:
Version: X.Y.Z → X'.Y'.Z'
Modified principles: [old → new] | (none)
Added sections: ...
Removed sections: ...
Templates requiring updates: ✅ <path> | ⚠ <path pending>
Follow-up TODOs: ...
-->

# [Project Name] Constitution

## Core Principles

### I. [Principle Name] (NON-NEGOTIABLE)

[2-3 sentence statement using MUST / MUST NOT language with rationale.]

### II. [Principle Name]

[...]

## [Optional Section: Quality Gates / Security Constraints / Performance Standards]

[High-level only. File-type specifics belong in instructions.]

## Governance

This constitution supersedes other development practices when in conflict.

Amendments require:
1. Documented rationale
2. Sync Impact Report prepended to this file
3. Version bump per the rules below

**Versioning**:

- MAJOR: principle removal or backward-incompatible rule change
- MINOR: principle addition or materially expanded section
- PATCH: wording, typo, clarification — no semantic change

All PRs MUST verify compliance. Complexity beyond these standards MUST be justified.

**Version**: X.Y.Z | **Ratified**: YYYY-MM-DD | **Last Amended**: YYYY-MM-DD
```

## Phase 4 — Sync Impact Report

Required output. Prepend as an HTML comment at the top of the file. If you do not produce this, the constitution change is incomplete.

The report MUST include:

- **Version change**: old → new (with reasoning if version bump is ambiguous)
- **Modified principles**: each rename or rewording, old → new
- **Added sections** / **Removed sections**
- **Templates requiring updates**: ✅ for files already synced, ⚠ for files still pending (e.g., `instructions/X.instructions.md` if a principle implies a new rule)
- **Follow-up TODOs**: deferred placeholders, decisions postponed

## Phase 5 — Propagate

For each principle added / removed / modified:

- Scan `instructions/*.instructions.md` for conflicting rules — flag them in the Sync Impact Report
- Scan `skills/*/SKILL.md` for outdated cross-references to constitution sections
- Do NOT auto-edit those files — list them under "Templates requiring updates" so a human can decide

## Rules

- **200-line hard limit** — if the file exceeds 200 lines, rules belong elsewhere (instructions / ADR / inline comments)
- **MUST / MUST NOT language** — every principle is testable / verifiable. "Should consider" is not a principle.
- **No file-type rules** — "all Java code MUST..." is fine; "use `try-with-resources` for `AutoCloseable`" is an instruction, not a principle
- **No feature-specific rules** — "user authentication MUST..." is suspect; constitution is project-wide
- **Sync Impact Report is non-negotiable** — every amendment generates one
- **Semver applied strictly** — do not bump MAJOR for a typo, do not bump PATCH for a removal

## Handoffs

- → instructions update — when a new principle implies file-type rules; create or amend the matching `instructions/X.instructions.md`


- ← all skills — constitution is upstream of every other workflow
