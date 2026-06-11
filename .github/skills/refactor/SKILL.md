---
name: refactor
description: 'Use when existing code needs structural improvement without changing behavior — extract method, rename, eliminate duplication, simplify logic. Triggers on: refactor, clean up, extract method, rename, reduce duplication, 重構, 整理程式碼, 拆方法, 改名. Produces behavior-preserving structural changes. Do NOT use for new features (prefer implement) or bug fixes (prefer debug).'
---

# Refactor — Workflow

Surgical, behavior-preserving structural changes.

**MANDATORY pre-load gate — do NOT apply a refactoring (Safe Process step 3) until you have opened the instruction files for the layers you touch.** Your training data defaults to modern Java/Spring; these files are the version lock for Java 8 / Spring 3.2 / Hibernate 4.2. Open them first, every time — the negative lists in the agent body are a floor, not the full rules:

- `instructions/java.instructions.md` — Java 8 language boundary
- `instructions/spring-hibernate.instructions.md` — Spring 3.2 + Hibernate 4.2
- `instructions/sql.instructions.md` — SQL injection, indexing, JDBC resources
- `instructions/security.instructions.md` — OWASP Top 10
- `instructions/jsp.instructions.md` — JSP / JSTL, XSS
- `instructions/xml-config.instructions.md` — Spring XML, hbm.xml, Maven POM
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

## Safe Process

1. **Identify the smell**: name it precisely (God Class, Long Method, Feature Envy, Duplicated Code, etc.)
2. **Verify preconditions**: understand all callers and dependents before touching anything
3. **Apply one refactoring at a time**: extract → rename → simplify. Never combine.
4. **Verify after each step**: behavior must be identical — check callers still work

## Common Operations

| Smell | Refactoring | Safety check |
|---|---|---|
| Long method (>30 lines of logic) | Extract Method | All local vars accounted for; return type clear |
| Duplicated code | Extract to shared method/utility | Both call sites produce identical behavior |
| Feature Envy | Move Method to the class it envies | Update all references; check access modifiers |
| God Class | Extract Class by responsibility | Each extracted class has single purpose |
| Long parameter list (>4 params) | Introduce Parameter Object | All callers updated; immutable DTO preferred |
| Primitive Obsession | Replace with domain type | Validation in constructor; all usages updated |

## Rules

- **Never change behavior while refactoring** — if you find a bug, log it separately
- **Smallest possible diff** — one smell per refactoring session
- **Preserve tests** — if existing tests break, the refactoring is wrong
- **Update callers** — use search to find every reference before renaming/moving

## Handoffs

- → `@reviewer` — for review after refactoring
- → `implement` skill — if refactoring reveals a need for new code
- ← `@implementer` — when code needs cleanup before feature work
- ← `implement` skill — if existing code needs restructuring first
