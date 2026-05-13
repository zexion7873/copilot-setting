---
agent: 'agent'
description: 'SDD specification template covering background, design, API specs, schema changes, acceptance criteria, NFRs, and out-of-scope. Pairs with skills/sdd/SKILL.md (workflow / readiness check / validation).'
---

# SDD Template

One-shot scaffold for a Spec-Driven Development document. Workflow (readiness check, drafting order, validation rules) lives in `skills/sdd/SKILL.md`. This prompt only defines the OUTPUT FORMAT.

## Usage

Invoke via `/spec-template`. Fill every placeholder — placeholders left as-is fail validation. For complex multi-component features, run the `sdd` skill instead of using this template raw.

## Template

```md
# SDD: ${input:featureTitle:Feature or change title}

**Author**: ${input:author}
**Date**: ${input:date:YYYY-MM-DD}
**Status**: Draft | In Review | Approved

## 1. Background & Objectives

Why this change is needed. Business context, user pain point, or technical driver. State the goal as a measurable outcome, not an activity.

## 2. Current State

How the system works today in the affected area. Include a Mermaid diagram if multiple components interact.

## 3. Proposed Design

### 3.1 Architecture

High-level design with a Mermaid diagram. Show component interactions, data flow, and boundaries.

### 3.2 API Specification

For each new or modified endpoint:

- **Method + Path**: `GET /api/orders/{customerId}`
- **Request**: schema, validation rules
- **Response**: schema, status codes
- **Errors**: error codes and messages
- **Auth**: required role / scope

### 3.3 Data Model / Schema Changes

New tables, altered columns, indexes. Migration steps and rollback strategy MUST be included.

### 3.4 Key Algorithms / Business Rules

Non-trivial logic the implementer must follow exactly. Pseudocode is fine; ambiguous prose is not.

## 4. Acceptance Criteria

Numbered, testable, binary pass/fail. No subjective language.

- AC-001: When [precondition], the system MUST [behavior].
- AC-002: ...

## 5. Non-Functional Requirements

- Performance targets (e.g., p95 < 200ms)
- Security constraints (e.g., OWASP A01 — access control on all endpoints)
- Compatibility requirements (e.g., backward-compatible API)

## 6. Dependencies & Risks

- DEP-001: External library / internal service this depends on
- RISK-001: Risk description — mitigation: ...

## 7. Files to Change

- FILE-001: `path/to/File.java` — what changes here

## 8. Out of Scope

Explicitly list what this SDD does NOT cover. This prevents scope creep during implementation.

- Not included: ...
- Future work: ...
```

## Validation Checklist

- [ ] Every `${input:...}` placeholder replaced
- [ ] No `TBD` / `TODO` / `...` left in the body
- [ ] Every AC uses MUST / MUST NOT and is binary pass/fail
- [ ] Every `FILE-NNN` references a real file in the codebase
- [ ] §3.3 schema changes include rollback strategy
- [ ] §8 Out of Scope is non-empty
