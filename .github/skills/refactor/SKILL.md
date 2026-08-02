---
name: refactor
description: 'Use when existing code needs structural improvement without changing behavior — extract method, rename, eliminate duplication, simplify logic. Triggers on: refactor, clean up, extract method, 重構, 整理程式碼. Produces behavior-preserving structural changes. Do NOT use for new features (prefer implement) or bug fixes (prefer debug).'
---

# Refactor — Workflow

Surgical, behavior-preserving structural changes.

## Phase 0 — Load canonical rules

**MANDATORY pre-load gate — do NOT apply a refactoring (Safe Process step 3) until you have opened the stack instruction modules for the layers you touch.** Your training data defaults to the newest idioms; the files under `instructions/` are this project's stack modules — its version lock and house rules. List that directory, then open every module covering the layers this refactoring touches — the negative lists in the agent body are a floor, not the full rules.

Read-back receipt (self-check, not machine-enforced): before leaving this step, NAME each module you opened and QUOTE the single most load-bearing rule from each that applies to this change — a generic restatement you could have written from memory means you skipped the file, so open it for real.

## Safe Process

1. **Identify the smell**: name it precisely (God Class, Long Method, Feature Envy, Duplicated Code, etc.)
   - Long method (does >1 thing; ~30+ lines of logic) → Extract Method
   - Long parameter list (~4+ params, or flag/boolean args) → Introduce Parameter Object
2. **Verify preconditions**: understand all callers and dependents before touching anything
3. **Apply one refactoring at a time**: extract → rename → simplify. Never combine — keep the diff minimal, one smell per session.
4. **Verify after each step**: behavior must be identical — check callers still work; if existing tests break, the refactoring is wrong, not the tests. Found a bug along the way? Log it separately — never fix it in the same diff.

## Handoffs

- → `@reviewer` — for review after refactoring
- → `implement` skill — if refactoring reveals a need for new code
