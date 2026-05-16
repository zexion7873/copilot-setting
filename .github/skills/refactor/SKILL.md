---
name: refactor
description: 'Use when existing code needs structural improvement without changing behavior — extract method, rename, eliminate duplication, simplify logic. Triggers on: refactor, clean up, extract method, rename, reduce duplication, 重構, 整理程式碼, 拆方法, 改名. Produces behavior-preserving structural changes. Do NOT use for new features (prefer implement), bug fixes (prefer debug), or performance optimization (prefer performance).'
---

# Refactor — Workflow

Surgical, behavior-preserving structural changes.

Full coding rules in `instructions/*.instructions.md`. Key rules:

- **Java 8 only**: no modern syntax — see `instructions/java.instructions.md`
- **Hibernate/Spring**: preserve tx boundaries and session lifecycle — see `instructions/spring-hibernate.instructions.md`
- **SQL**: maintain parameterized queries — see `instructions/sql.instructions.md`

## Smell → Refactoring Map

| Smell | Refactoring | Safety check |
|---|---|---|
| Long method (>30 lines) | Extract Method | All local vars accounted for; return type clear |
| Duplicated code | Extract shared method | Both call sites produce identical behavior |
| Feature Envy | Move Method | Update all references; check access modifiers |
| God Class | Extract Class | Each class has single purpose |
| Long parameter list (>4) | Parameter Object | All callers updated; immutable DTO preferred |
| Primitive Obsession | Domain type | Validation in constructor; all usages updated |

## Rules

- Never change behavior while refactoring — if you find a bug, log it separately
- One smell per refactoring session
- Smallest possible diff
- Preserve existing tests — if they break, the refactoring is wrong
- Search for every reference before renaming/moving

## Handoffs

- → `@reviewer` — for review after refactoring
- → `implement` skill — refactoring reveals need for new code
- ← `@implementer` — code needs cleanup before feature work
