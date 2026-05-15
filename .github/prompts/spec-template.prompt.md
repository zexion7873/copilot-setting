---
agent: 'agent'
description: 'SDD specification scaffold — background, requirements, design, API contract, data model, testing. Pairs with skills/sdd/SKILL.md (workflow).'
---

# Spec Template (SDD)

One-shot scaffold for a Spec-Driven Development document. Workflow: `skills/sdd/SKILL.md`.

## Usage

Invoke via `/spec-template`. Fill placeholders, name file `sdd-[feature]-v[N].md`.

## Template

```md
---
title: ${input:title:Feature name}
date: ${input:date:YYYY-MM-DD}
author: ${input:author}
status: 'Draft'
---

# ${input:title}

## 1. Background

Why this change exists. Business context and motivation.

## 2. Requirements

- REQ-001: <testable requirement with pass/fail criteria>
- REQ-002: ...

## 3. Design

### Approach

High-level approach with rationale. Why this over alternatives.

### Alternatives Considered

- ALT-001: <approach> — rejected because <reason>

## 4. API Contract

| Method | Signature | Input | Output | Errors |
|---|---|---|---|---|
| ... | ... | ... | ... | ... |

## 5. Data Model

Entity/table changes. Migration script needed: yes/no. Rollback plan.

## 6. Error Handling

| Failure Mode | Detection | Recovery |
|---|---|---|
| ... | ... | ... |

## 7. Testing Strategy

- TEST-001: <what to verify> — <how> — maps to REQ-NNN
- TEST-002: ...

## 8. Out of Scope

What is explicitly NOT included in this work.
```

## Validation Checklist

- [ ] Every `${input:...}` placeholder replaced
- [ ] Every requirement has pass/fail criteria
- [ ] API contracts include error responses
- [ ] Data model notes migration/rollback needs
- [ ] Testing strategy maps to requirements
