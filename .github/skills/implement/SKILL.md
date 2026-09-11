---
name: implement
description: 'Use when user needs code written — new features or task execution in Java 8 / Maven / Spring / Hibernate projects. Triggers on: implement, code this, write code, 實作, 幫我寫. Produces working code following existing patterns. Do NOT use for refactoring without new behavior (prefer refactor) or bug investigation (prefer debug).'
---

# Implement — Workflow

Feature implementation for Java 8 / Maven / Spring Core / Hibernate 4.2 projects.

## Phase 0 — Load canonical rules

**MANDATORY pre-load gate — do NOT write code (Phase 2) until you have opened the instruction files for the layers you touch.** Your training data defaults to modern Java/Spring; these files are the version lock for Java 8 / Spring 3.2 / Hibernate 4.2. Open them first, every time — the negative lists in the agent body are a floor, not the full rules. Read-back receipt: NAME each file you opened and QUOTE its single most load-bearing rule for this change — a generic restatement you could have written from memory means you skipped the file.

Layers you touch — open each one: `instructions/java.instructions.md`, `instructions/spring-hibernate.instructions.md`, `instructions/sql.instructions.md`, `instructions/sql-ddl.instructions.md`, `instructions/security.instructions.md`, `instructions/jsp.instructions.md`, `instructions/xml-config.instructions.md`, `instructions/testing.instructions.md` (the last when writing tests).

## Phase 1 — Understand Context & Discover Patterns

Before writing new code, find and follow existing patterns:
- DAO pattern: how other DAOs use `SessionFactory`
- Service pattern: how tx boundaries are structured
- Error handling: project's exception hierarchy
- Naming: existing conventions for classes, methods, variables
- Affected files and their callers/dependents

## Phase 2 — Implement

- Match existing patterns exactly — consistency over personal preference
- One logical change per commit scope
- Add logging at INFO for business events, DEBUG for diagnostics
- Handle errors at the right layer; translate at boundaries

## Phase 3 — Self-Verify

- [ ] Ran `mvn compile` and the relevant tests — actually green, not assumed
- [ ] Follows patterns found in Phase 1
- [ ] Ran `grep -rnE '@Entity|@Table|@Column|openSession\(|beginTransaction\(' <changed files>` — zero hits, or each `beginTransaction(` hit consciously justified as non-advised code per `instructions/spring-hibernate.instructions.md` (the first four compile but violate the Spring 3.2 / Hibernate 4.2 lock; the grep is mechanical, the `beginTransaction(` justification is the only judgement step)
- [ ] No `@Transactional` on NEW production code (use `<tx:advice>`); test-class auto-rollback usage is sanctioned per `instructions/testing.instructions.md`; a module already consistently `@Transactional` may sustain it per `instructions/spring-hibernate.instructions.md`
- [ ] SQL uses parameterized queries only
- [ ] No hardcoded secrets or credentials

## Handoffs

- → `verify` skill — to gate the change against its acceptance criteria (close the loop; a red gate comes back here to fix)
- → `@reviewer` — for code review after implementation
- → `debug` skill — if implementation reveals a bug
- → `refactor` skill — if existing code needs restructuring first
