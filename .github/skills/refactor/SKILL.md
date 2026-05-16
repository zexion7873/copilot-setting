---
name: refactor
description: 'Use when existing code needs structural improvement without changing behavior — extract method, rename, eliminate duplication, simplify logic. Triggers on: refactor, clean up, extract method, rename, reduce duplication, 重構, 整理程式碼, 拆方法, 改名. Produces behavior-preserving structural changes. Do NOT use for new features (prefer implement), bug fixes (prefer debug), or performance optimization (prefer performance).'
---

# Refactor — Workflow

Surgical, behavior-preserving structural changes.

Full coding rules in `instructions/*.instructions.md`. Key rules (fallback for agent chat):

- **Java 8**: no `var`, no `List.of()`, no records — checked exceptions must be handled or declared
- **Spring 3.2**: XML config + `<tx:advice>` only, no `@Transactional`, no Spring Boot
- **Hibernate 4.2**: `getCurrentSession()` only, `hbm.xml` mappings, no JPA annotations
- **SQL (JDBC)**: `PreparedStatement` with `?` — zero string concatenation
- **SQL (HQL)**: named parameters (`:param`) — never concatenate into query strings
- **Security**: `<c:out>` for all JSP output; `HttpOnly` + `Secure` cookie flags

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
