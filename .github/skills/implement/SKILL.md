---
name: implement
description: 'Use when user needs code written — new features or task execution following the declared project stack. Triggers on: implement, code this, write code, 實作, 幫我寫. Produces working code following existing patterns. Do NOT use for refactoring without new behavior (prefer refactor) or bug investigation (prefer debug).'
---

# Implement — Workflow

Feature implementation following the declared project stack and existing patterns.

## Phase 0 — Load canonical rules

**MANDATORY pre-load gate — do NOT write code (Phase 3) until you have opened the stack instruction modules for the layers you touch.** Your training data defaults to the newest idioms; the files under `instructions/` are this project's stack modules — its version lock and house rules. List that directory, then open every module covering the layers this change touches (include the testing module when writing tests) — the negative lists in the agent body are a floor, not the full rules.

Read-back receipt (self-check, not machine-enforced): before leaving this step, NAME each module you opened and QUOTE the single most load-bearing rule from each that applies to this change — a generic restatement you could have written from memory means you skipped the file, so open it for real.

## Phase 1 — Understand Context

1. Read the task / user request
2. Scan existing code for patterns: naming, layering, error handling, logging
3. Identify affected files and their callers/dependents

## Phase 2 — Discover Patterns

Before writing new code, find and follow existing patterns:
- Data-access pattern: how existing code obtains and releases connections/sessions
- Service pattern: how transaction boundaries are structured
- Error handling: project's exception hierarchy
- Naming: existing conventions for classes, methods, variables

## Phase 3 — Implement

- Match existing patterns exactly — consistency over personal preference
- One logical change per commit scope
- Add logging at INFO for business events, DEBUG for diagnostics
- Handle errors at the right layer; translate at boundaries

## Phase 4 — Self-Verify

- [ ] Ran the project's build and the relevant tests — actually green, not assumed
- [ ] Follows patterns found in Phase 2
- [ ] Expanded every construct the agent floor (`## Coding Standards`) bans into its concrete symbols and ran a grep across the changed files — zero hits, or each hit consciously justified per the matching stack module (the grep is mechanical; the justification is the only judgement step)
- [ ] SQL uses parameterized queries only
- [ ] No hardcoded secrets or credentials

## Handoffs

- → `verify` skill — to gate the change against its acceptance criteria (close the loop; a red gate comes back here to fix)
- → `@reviewer` — for code review after implementation
- → `debug` skill — if implementation reveals a bug
- → `refactor` skill — if existing code needs restructuring first
