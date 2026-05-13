---
name: sdd
description: 'Use when user asks to write an SDD, create a spec document, or adopt spec-driven development. Triggers on: write SDD, create spec document, Spec-Driven Development, 寫 SDD, 寫規格文件, 規格驅動開發, 先定規格再實作, 定義規格, spec before code. Produces a formal SDD covering design, API specs, schema changes, and acceptance criteria. Do NOT use for implementation plans without spec depth (prefer plan skill), quick bug fixes, general documentation (prefer @doc-writer directly), or architectural decision records (prefer adr skill).'
---

# SDD (Spec-Driven Development) — Workflow

Create a formal specification document BEFORE implementation begins. The SDD is the contract between planning and coding — implementation must comply with it.

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

## Phase 2 — Draft SDD

Use this structure. Every section must be populated — no placeholders.

```md
# SDD: [Feature / Change Title]

## 1. Background & Objectives

Why this change is needed. Business context, user pain point, or technical driver.

## 2. Current State

How the system works today in the affected area. Include Mermaid diagrams for architecture if multiple components are involved.

## 3. Proposed Design

### 3.1 Architecture

High-level design with Mermaid diagrams. Show component interactions, data flow, and boundaries.

### 3.2 API Specification

For each new or modified endpoint: method, path, request/response format, error codes, auth requirements.

### 3.3 Data Model / Schema Changes

New tables, altered columns, indexes, migration steps. Include rollback strategy.

### 3.4 Key Algorithms / Business Rules

Non-trivial logic that the implementer must follow exactly.

## 4. Acceptance Criteria

Numbered list. Each criterion is testable and unambiguous.

- AC-001: ...
- AC-002: ...

## 5. Non-Functional Requirements

Performance targets, security constraints, compatibility requirements.

## 6. Dependencies & Risks

- DEP-001: ...
- RISK-001: ... — mitigation: ...

## 7. Files to Change

- FILE-001: `path/to/File.java` — what changes here

## 8. Out of Scope

Explicitly list what this SDD does NOT cover to prevent scope creep.
```

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

- → `@implementer` / `implement` skill — once SDD is approved, start coding against it
- → `@reviewer` — review implementation against SDD compliance
- ← `plan` skill — a plan often becomes the foundation for an SDD
- ← `@planner` — planner may suggest creating an SDD for complex features
