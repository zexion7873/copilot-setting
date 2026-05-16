---
name: implement
description: 'Use when user needs code written — new features, SDD implementation, or task execution in Java 8 / Maven / Spring / Hibernate projects. Triggers on: implement, code this, build feature, write code, 實作, 寫程式, 開始做, 幫我寫. Produces working code following existing patterns. Do NOT use for refactoring without new behavior (prefer refactor), performance tuning (prefer performance), or bug investigation (prefer debug).'
---

# Implement — Workflow

Feature implementation for Java 8 / Maven / Spring 3.2 / Hibernate 4.2 projects.

Full coding rules in `instructions/*.instructions.md`. Key rules:

- **Java 8 only**: no `var`, no `List.of()`, no records — see `instructions/java.instructions.md`
- **Hibernate**: `getCurrentSession()` only, hbm.xml mappings, no JPA annotations — see `instructions/spring-hibernate.instructions.md`
- **Transactions**: XML `<tx:advice>` only, no `@Transactional`, no `@RestController` — see `instructions/spring-hibernate.instructions.md`
- **SQL**: `PreparedStatement` with `?` only — see `instructions/sql.instructions.md`
- **Security**: no hardcoded secrets; encode all JSP output — see `instructions/security.instructions.md`

## Before Writing Code

- Read the SDD / task / user request
- Scan existing code for patterns: naming, layering, error handling, logging
- Identify affected files and their callers/dependents
- Match existing patterns exactly — consistency over personal preference

## Self-Verify Checklist

- [ ] Compiles without warnings
- [ ] Follows patterns found in existing code
- [ ] No `@Transactional`, no `openSession()`, no JPA annotations, no `@RestController`
- [ ] SQL uses parameterized queries only
- [ ] No hardcoded secrets or credentials

## Handoffs

- → `@reviewer` — for code review after implementation
- → `debug` skill — if implementation reveals a bug
- → `refactor` skill — if existing code needs restructuring first
- ← `tasks` skill — executing a task list
