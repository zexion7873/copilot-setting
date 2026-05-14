---
name: clarify-task
description: 'Use when user request is vague, ambiguous, or missing scope / deliverable / constraints. Triggers on: vague request, ambiguous scope, unclear requirements, need clarification, where to start, uncertain about approach, 需求不清楚, 先釐清一下, 應該怎麼開始, 我不確定該怎麼做, 範圍是什麼, 不太懂要做什麼. Iteratively refines understanding via numbered clarifying questions before any code or file is touched. Do NOT use when the task is already well-specified (just do it), for trivial single-line edits, for direct factual questions, or when user asks to look at / review specific code (prefer code-review).'
---

# Clarify Task — Workflow

Be properly informed before acting. Ambiguous requests produce wrong outputs faster than they save time. This skill is the gate before `implement` / `refactor` / `plan` when scope is unclear.

## When to Trigger

- Request lacks a measurable success criterion ("make it better", "fix the auth")
- Multiple plausible interpretations exist
- Request implies large surface area but is described in one sentence
- Stakes are high (production code, data migration, security)

Skip if the user has already supplied scope, files, and acceptance criteria — going through this skill would just be friction.

## Phase 1 — Identify the Gaps

Before asking anything, write down internally:

```
What I know:        <facts from the request + visible code>
What I don't know:  <unknowns blocking action>
What I assume:      <implicit assumptions worth verifying>
```

Only ask about items in **don't know** + critical items in **assume**. Do not ask about things you can resolve by reading a file.

## Phase 2 — Ask in Chat (Numbered)

Present clarifying questions as a numbered list, grouped by topic. Wait for the user before proceeding.

```
**Scope**
1. Should this apply to existing records, new records only, or both?
2. Are admin users in scope?

**Deliverable**
3. Code change only, or also docs / tests?
4. Where should the new module live?

**Constraints**
5. Any deadline?
6. Any backward-compat requirement for clients on v2?
```

Rules:
- Specific, answerable questions — not "what do you want?"
- Group related questions
- 3–7 questions total; if you need more, the request is too big — split it first

## Phase 3 — Explore the Codebase

While waiting (or after answers), use search / read tools to confirm assumptions and surface details the user didn't mention. Note discoveries that might change the plan.

## Phase 4 — Confirm Understanding

Summarize back in 5–10 lines:

```
Understanding:
- Goal: …
- In scope: …
- Out of scope: …
- Acceptance: …
- Approach (high level): …

Anything to add or correct?
```

## Phase 5 — Proceed

Once the user confirms, hand off:

- → `plan` skill — for multi-step / multi-file work
- → `implement` skill — for direct execution
- → `refactor` skill — for behavior-preserving restructuring
- → `debug` skill — if the real task turned out to be a bug hunt

## Handoffs

- → `plan` skill — for multi-step / multi-file work
- → `implement` skill — for direct execution
- → `refactor` skill — for behavior-preserving restructuring
- → `debug` skill — if the real task turned out to be a bug hunt

## Anti-Patterns

- Asking questions that the code answers — read it first
- Asking 15 questions at once — bundle, prioritize, top 5
- Proceeding without confirmation when the user's answers contradict each other — re-summarize and re-confirm
- Using this skill for "rename this variable" — it's friction, not value
