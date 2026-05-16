---
agent: 'agent'
description: 'Implementation plan scaffold — phases, requirements, files, risks. Pairs with skills/plan/SKILL.md (workflow). For task decomposition, use prompts/tasks-template.prompt.md.'
---

# Plan Template

One-shot scaffold for an implementation plan. Workflow: `skills/plan/SKILL.md`. Task decomposition: `prompts/tasks-template.prompt.md`.

## Usage

Invoke via `/plan-template`. Fill placeholders, name file `[purpose]-[component]-v[N].md`.

## Template

```md
---
goal: ${input:goal:Concise plan title}
date: ${input:date:YYYY-MM-DD}
owner: ${input:owner}
status: 'Planned'
---

# ${input:goal}

## 1. Requirements & Constraints

- REQ-001: <functional requirement>
- CON-001: <constraint — e.g., Java 8, no Spring Boot>
- PAT-001: <existing pattern to follow>

## 2. Implementation Approach

### Phase 1 — <Goal>

- What this phase achieves
- Approach: components touched, order of work

### Phase 2 — <Goal>

- ...

## 3. Files

- FILE-001: `path/to/File.java` — what changes
- FILE-002: ...

## 4. Risks & Alternatives

- RISK-001: <risk> — mitigation: <specific action>
- ALT-001: <alternative considered> — rejected because <reason>

## 5. Dependencies

- DEP-001: <external or internal dependency>
```

## Validation Checklist

- [ ] Every `${input:...}` placeholder replaced
- [ ] No `TBD` / `TODO` left
- [ ] Every phase has a single, measurable goal
- [ ] Every `FILE-NNN` references a real file
- [ ] At least one alternative with rejection reason
