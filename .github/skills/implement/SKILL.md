---
name: implement
description: 'Use when user needs code written — new features, SDD implementation, or task execution in Java 8 / Maven / Spring / Hibernate projects. Triggers on: implement, code this, build feature, write code, 實作, 寫程式, 開始做, 幫我寫. Produces working code following existing patterns. Do NOT use for refactoring without new behavior (prefer refactor), performance tuning (prefer performance), or bug investigation (prefer debug).'
---

# Implement — Workflow

Feature implementation for Java 8 / Maven / Spring Core / Hibernate 4.x projects.

**Canonical rules — open the instruction files for the layers you touch** (agent mode can read them directly):

- `instructions/java.instructions.md` — Java 8 language boundary
- `instructions/spring-hibernate.instructions.md` — Spring 3.2 + Hibernate 4.2
- `instructions/sql.instructions.md` — SQL injection, indexing, JDBC resources
- `instructions/security.instructions.md` — OWASP Top 10
- `instructions/jsp.instructions.md` — JSP / JSTL, XSS
- `instructions/xml-config.instructions.md` — Spring XML, hbm.xml, Maven POM
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

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
