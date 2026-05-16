---
name: implement
description: 'Use when user needs code written — new features, SDD implementation, or task execution in Java 8 / Maven / Spring / Hibernate projects. Triggers on: implement, code this, build feature, write code, 實作, 寫程式, 開始做, 幫我寫. Produces working code following existing patterns. Do NOT use for refactoring without new behavior (prefer refactor), performance tuning (prefer performance), or bug investigation (prefer debug).'
---

# Implement — Workflow

Feature implementation for Java 8 / Maven / Spring Core / Hibernate 4.x projects.

Full coding rules in `instructions/*.instructions.md`. Key rules (fallback for agent chat):

- **Java 8**: no `var`, no `List.of()`, no records — checked exceptions must be handled or declared
- **Spring 3.2**: XML config + `<tx:advice>` only, no `@Transactional`, no Spring Boot
- **Hibernate 4.2**: `getCurrentSession()` only, `hbm.xml` mappings, no JPA annotations
- **SQL (JDBC)**: `PreparedStatement` with `?` — zero string concatenation
- **SQL (HQL)**: named parameters (`:param`) — never concatenate into query strings
- **Security**: `<c:out>` for all JSP output; `HttpOnly` + `Secure` cookie flags

## Phase 1 — Understand Context

1. Read the SDD / task / user request
2. Scan existing code for patterns: naming, layering, error handling, logging
3. Identify affected files and their callers/dependents

## Phase 2 — Discover Patterns

Before writing new code, find and follow existing patterns:
- DAO pattern: how other DAOs use `SessionFactory`
- Service pattern: how tx boundaries are structured
- Error handling: project's exception hierarchy
- Naming: existing conventions for classes, methods, variables

## Phase 3 — Implement

- Match existing patterns exactly — consistency over personal preference
- One logical change per commit scope
- Add logging at INFO for business events, DEBUG for diagnostics
- Handle errors at the right layer; translate at boundaries

## Phase 4 — Self-Verify

- [ ] Compiles without warnings
- [ ] Follows patterns found in Phase 2
- [ ] No `@Transactional`, no `openSession()`, no JPA annotations
- [ ] SQL uses parameterized queries only
- [ ] No hardcoded secrets or credentials

## Handoffs

- → `@reviewer` — for code review after implementation
- → `debug` skill — if implementation reveals a bug
- → `refactor` skill — if existing code needs restructuring first
- ← `@implementer` — default activation
- ← `tasks` skill — executing a task list
