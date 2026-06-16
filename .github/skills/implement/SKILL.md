---
name: implement
description: 'Use when user needs code written — new features or task execution in Java 8 / Maven / Spring / Hibernate projects. Triggers on: implement, code this, build feature, write code, 實作, 寫程式, 開始做, 幫我寫. Produces working code following existing patterns. Do NOT use for refactoring without new behavior (prefer refactor) or bug investigation (prefer debug).'
---

# Implement — Workflow

Feature implementation for Java 8 / Maven / Spring Core / Hibernate 4.2 projects.

## Phase 0 — Load canonical rules

**MANDATORY pre-load gate — do NOT write code (Phase 3) until you have opened the instruction files for the layers you touch.** Your training data defaults to modern Java/Spring; these files are the version lock for Java 8 / Spring 3.2 / Hibernate 4.2. Open them first, every time — the negative lists in the agent body are a floor, not the full rules:

- `instructions/java.instructions.md` — Java 8 language boundary
- `instructions/spring-hibernate.instructions.md` — Spring 3.2 + Hibernate 4.2
- `instructions/sql.instructions.md` — SQL injection, indexing, JDBC resources
- `instructions/security.instructions.md` — OWASP Top 10
- `instructions/jsp.instructions.md` — JSP / JSTL, XSS
- `instructions/xml-config.instructions.md` — Spring XML, hbm.xml, Maven POM
- `instructions/testing.instructions.md` — JUnit 4 / Mockito / Spring Test 3.2 (when writing tests)
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

Read-back receipt (self-check, not machine-enforced): before leaving this step, NAME each instruction file you opened above and QUOTE the single most load-bearing rule from each that applies to this change — a generic restatement you could have written from memory means you skipped the file, so open it for real.

## Phase 1 — Understand Context

1. Read the task / user request
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

- [ ] Ran `mvn compile` and the relevant tests — actually green, not assumed
- [ ] Follows patterns found in Phase 2
- [ ] Ran `grep -rnE '@Entity|@Table|@Column|openSession\(|beginTransaction\(' <changed files>` — zero hits, or each `beginTransaction(` hit consciously justified as non-advised code per `instructions/spring-hibernate.instructions.md` (the first four compile but violate the Spring 3.2 / Hibernate 4.2 lock; the grep is mechanical, the `beginTransaction(` justification is the only judgement step)
- [ ] No `@Transactional` on NEW production code (use `<tx:advice>`); test-class auto-rollback usage is sanctioned per `instructions/testing.instructions.md`; a module already consistently `@Transactional` may sustain it per `instructions/spring-hibernate.instructions.md`
- [ ] SQL uses parameterized queries only
- [ ] No hardcoded secrets or credentials

## Handoffs

- → `@reviewer` — for code review after implementation
- → `debug` skill — if implementation reveals a bug
- → `refactor` skill — if existing code needs restructuring first
