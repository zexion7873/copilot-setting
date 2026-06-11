---
name: clarify-task
description: 'Use when a user request is vague, ambiguous, or missing critical information and needs refinement before planning or implementation. Triggers on: clarify, unclear requirements, what do you mean, 先釐清, 需求不清楚, 這個需求是什麼意思, 幫我確認. Produces numbered clarifying questions and a confirmed understanding summary. Do NOT use for well-defined tasks ready for planning (prefer plan) or direct implementation (prefer implement).'
---

# Clarify Task — Workflow

Interactive task refinement. Use before planning when requirements have gaps.

## Phase 1 — Parse the Request

Extract from the user's message:
- **Goal**: what they want to achieve (may be implicit)
- **Scope**: which modules/files/features are involved
- **Constraints**: deadlines, tech limitations, backward compatibility

## Phase 2 — Identify Gaps

Flag anything that would force guessing during implementation:
- Missing acceptance criteria
- Ambiguous scope boundaries
- Unstated assumptions about existing behavior
- Conflicting requirements

## Phase 3 — Ask Numbered Questions

Present 3–7 numbered questions. Each question:
1. States what is unclear
2. Offers 2–3 concrete options when possible
3. Marks a recommended default if one exists

Do NOT ask questions the codebase can answer — scan first, ask only what code cannot tell you.

## Phase 4 — Confirm Understanding

After answers, produce a summary block:

```
## Confirmed Understanding
- Goal: ...
- Scope: ...
- Constraints: ...
- Out of scope: ...
- Open items: ... (if any remain)
```

## Handoffs

- → `plan` skill — when requirements are clear enough to plan
- → `implement` skill — when the task is small and fully understood
- ← `@planner` — when planner detects ambiguity before planning
- ← `plan` skill — if gaps found during planning
