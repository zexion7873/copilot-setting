---
name: refactor
description: 'Use when user asks to refactor, clean up, simplify, or restructure code without changing behavior. Triggers on: refactor, clean up, simplify, restructure, extract method, rename, eliminate code smell, decompose, 重構, 整理一下, 這段太亂了, 簡化, 拆開這個 method, 抽出方法, 重新命名. Covers extract method, rename, decompose large functions, and eliminate code smells. Do NOT use for bug fixes (prefer debug), writing new features or adding new endpoints (prefer implement), formatting-only changes, or when the goal is to review rather than modify (prefer code-review).'
---

# Refactor — Workflow

Improve structure without changing external behavior.

Full coding standards live in `instructions/*.instructions.md` (auto-applied when matching files are open). When working via agent chat, these non-negotiable rules still apply:

- **SQL**: never regress `PreparedStatement` to string concatenation during restructuring
- **Exceptions**: no empty `catch` blocks; maintain layer-boundary translation when extracting methods
- **Logging**: keep SLF4J parameterized — never introduce `+` concatenation
- **Resources**: preserve `try-with-resources` for all `AutoCloseable` — critical when extracting methods that handle connections
- **Security**: no hardcoded secrets; maintain input validation at boundaries

## Rules

1. **Behavior preserved** — change how, not what
2. **Small steps** — tiny change, verify, commit, repeat
3. **One thing at a time** — never mix refactor with feature change

## Code Smells & Fixes

| Smell | Fix |
|---|---|
| Long Method (100+ lines) | Extract Method per cohesive block |
| Duplicated Code | Extract shared helper |
| Large Class (20+ methods, unrelated concerns) | Split by responsibility |
| Long Parameter List (5+ params) | Parameter Object / Builder |
| Feature Envy | Move method to the data's owner |
| Primitive Obsession | Wrap in domain types |
| Nested Conditionals (4+ levels) | Guard clauses / early returns |
| Dead Code | Delete; git remembers |

## Common Operations

| Operation | When |
|---|---|
| Extract Method | Code block has a single purpose worth naming |
| Extract Class | Multiple methods share state unrelated to the rest |
| Inline Method/Class | Abstraction adds no value |
| Rename | Current name lies or is too vague |
| Replace Conditional with Polymorphism | `if (type == X)` repeats in many places |
| Decompose Conditional | Boolean expression takes 3+ seconds to read |

## Safe Refactoring Process

1. **Prepare**: commit current state; new branch
2. **Identify**: pick one smell; understand current behavior; plan target structure
3. **Refactor in micro-steps**: one change → verify → commit if green → repeat
4. **Verify**: full test pass; manual smoke if UI
5. **Clean up**: update affected comments/docs; final commit

## Multi-File Refactor Sequencing

1. Interfaces / abstract types first — establish new contract
2. Implementations — adapt one at a time
3. Call sites — migrate consumers
4. Cleanup — delete deprecated code, update docs

Each phase ends in a green build. One commit per phase for clean rollback.

## Handoffs

- → `code-review` / `@reviewer` — after refactoring for review
- → `plan` skill — if refactor spans many files, write a plan first

## Reference Examples

- `examples/extract-method.md` — Extract Method with thresholds (LOC > 15, NOM > 10, CC > 10)
- `examples/remove-parameter.md` — Remove Parameter (unused / redundant params)
