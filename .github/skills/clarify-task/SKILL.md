---
name: clarify-task
description: 'Use when a user request is vague, ambiguous, or missing critical information and needs refinement before planning or implementation. Triggers on: clarify, unclear requirements, what do you mean, 需求不清楚, 先釐清, 這個需求是什麼意思, 幫我確認. Produces numbered clarifying questions and a confirmed understanding summary. Do NOT use for well-defined tasks ready for planning (prefer plan) or direct implementation (prefer implement).'
---

# Clarify Task — Workflow

Interactive task refinement before planning or implementation.

## What to Extract

- **Goal**: what they want to achieve (may be implicit)
- **Scope**: which modules / files / features
- **Constraints**: deadlines, tech limitations, backward compatibility
- **Acceptance criteria**: how to know it's done

## What Needs Clarification

Flag anything that would force guessing:
- Missing acceptance criteria
- Ambiguous scope boundaries
- Unstated assumptions about existing behavior
- Conflicting requirements

Do NOT ask questions the codebase can answer — scan first.

## How to Ask

- 3–7 numbered questions
- Each states what is unclear + offers 2–3 concrete options
- Mark a recommended default when one exists

## Output

```
## Confirmed Understanding
- Goal: ...
- Scope: ...
- Constraints: ...
- Out of scope: ...
- Open items: ... (if any remain)
```

## Handoffs

- → `plan` skill — requirements clear enough to plan
- → `implement` skill — small task, fully understood
- ← `@planner` — planner detects ambiguity
