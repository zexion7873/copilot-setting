---
agent: 'agent'
description: 'Create an implementation plan file for a new feature, refactor, or upgrade. Output is a structured Markdown spec with phases, tasks, and acceptance criteria.'
tools: ['search/changes', 'search/codebase', 'edit/editFiles', 'web/fetch', 'read/problems']
---

# Create Implementation Plan

Create a new implementation plan file for `${input:PlanPurpose}`. The output is a self-contained Markdown spec that another developer (or AI) can execute without further clarification.

## Output

- Location: `/plan/` directory
- Filename: `[purpose]-[component]-[version].md`
  - Purpose prefixes: `upgrade` / `refactor` / `feature` / `data` / `infrastructure` / `process` / `architecture` / `design`
  - Examples: `upgrade-system-command-4.md`, `feature-auth-module-1.md`

## Template

```md
---
goal: [Concise title describing the plan's goal]
version: [e.g., 1.0]
date_created: [YYYY-MM-DD]
last_updated: [YYYY-MM-DD]
owner: [Team / individual responsible]
status: 'Completed' | 'In progress' | 'Planned' | 'Deprecated' | 'On Hold'
tags: [feature | upgrade | chore | architecture | migration | bug | ...]
---

# Introduction

[Short intro describing the plan and the goal it achieves.]

## 1. Requirements & Constraints

- **REQ-001**: Requirement 1
- **SEC-001**: Security requirement 1
- **CON-001**: Constraint 1
- **GUD-001**: Guideline 1
- **PAT-001**: Pattern to follow 1

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

- **ALT-001**: Alternative 1 — rejected because ...

## 4. Dependencies

- **DEP-001**: Dependency 1

## 5. Files

- **FILE-001**: Path / description

## 6. Testing

- **TEST-001**: Test plan item 1

## 7. Risks & Assumptions

- **RISK-001**: Risk 1
- **ASSUMPTION-001**: Assumption 1

## 8. Related Specifications

- [Link to related spec]
- [Link to external documentation]
```

## Rules

- Each task atomic and individually verifiable
- All identifiers use prefixes (`REQ-`, `TASK-`, `RISK-`, etc.)
- Phases independent unless a dependency is declared
- No placeholder text in the final output — every field populated
