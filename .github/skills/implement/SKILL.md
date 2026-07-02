---
name: implement
description: 'Use when user needs code written or restructured — new features, refactoring, test case design, or verifying an API against version-matched docs — in Java 8 / Maven / Spring / Hibernate projects. Triggers on: implement, write code, refactor, test cases, verify API, 實作, 寫程式, 重構, 測試案例, 查官方文件. Produces working code following existing patterns. Do NOT use for bug investigation (prefer debug).'
---

# Implement — Workflow

Feature implementation for Java 8 / Maven / Spring Core / Hibernate 4.2 projects. Includes three sub-modes: **Refactor** (behavior-preserving restructuring), **Test Design** (test case document), and **Source-Check** (version-matched API verification).

## Phase 0 — Load canonical rules

Before writing code, open the instruction files for the layers you touch — glob auto-loading does not fire for files you read mid-task, and your training data defaults to modern Java/Spring (these files are the version lock): `instructions/java.instructions.md`, `instructions/spring-hibernate.instructions.md`, `instructions/sql.instructions.md`, `instructions/security.instructions.md`, `instructions/jsp.instructions.md`, `instructions/xml-config.instructions.md`, `instructions/testing.instructions.md` (when writing tests), `instructions/no-heredoc.instructions.md`.

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
- [ ] Ran `grep -rnE '@Entity|@Table|@Column|openSession\(|beginTransaction\(' <changed files>` — zero hits, or each `beginTransaction(` hit consciously justified as non-advised code per `instructions/spring-hibernate.instructions.md`
- [ ] No `@Transactional` on NEW production code (use `<tx:advice>`); test-class auto-rollback usage is sanctioned per `instructions/testing.instructions.md`; a module already consistently `@Transactional` may sustain it per `instructions/spring-hibernate.instructions.md`
- [ ] SQL uses parameterized queries only
- [ ] No hardcoded secrets or credentials

## Refactor Mode

Surgical, behavior-preserving structural changes:

1. **Identify the smell precisely** — Long Method → Extract Method; Duplicated Code → extract shared method; Feature Envy → Move Method; God Class → Extract Class; Long parameter list → Parameter Object; Primitive Obsession → domain type
2. **Verify preconditions** — understand all callers and dependents before touching anything
3. **Apply one refactoring at a time** — never combine; keep the diff minimal, one smell per session
4. **Verify after each step** — behavior must be identical; if existing tests break, the refactoring is wrong, not the tests. Found a bug along the way? Log it separately — never fix it in the same diff.

## Test Design Mode

Produces a test case document (not test code); framework rules for the test code that follows: `instructions/testing.instructions.md`.

1. **Identify boundaries** — input (min/max/empty/null/overflow), state (initial/in-progress/completed/error), integration (external API, DB, file I/O)
2. **Classify categories** — Happy path, Boundary, Error/Exception (all must-have); Security (must-have for user-facing); Concurrency (if multi-threaded); Performance (if SLA exists)
3. **Audit coverage** — every requirement ≥1 case; every public method has happy + error case; boundary values covered; SQL tested for injection and empty results
4. **Write the document** to `docs/test-design/<component>-tests.md` (versioning is git history):

```md
---
source: <plan path or feature under test>
date: <YYYY-MM-DD>
---

# Test Design — <component>

## Test Cases

TC-NNN: <Short description>
Category: <Happy path | Boundary | Error | Security | Concurrency | Performance>
Precondition: <Setup required>
Input: <Specific values>
Expected result: <Exact expected outcome>
Priority: <High | Medium | Low>

## Coverage Audit

<audit results>
```

## Source-Check Mode

Verify a framework/library API against **version-matched** official docs before relying on it — recall is where deprecated-but-plausible signatures hide.

1. **Detect versions** — read `pom.xml` (and parent/BOM) for exact Spring / Hibernate / JDK versions; state them; ask if ambiguous
2. **Fetch the version-matched source** via `context7` (official version-pinned reference / Javadoc > changelog > reputable API reference; never blogs or recall); if the pinned version cannot be served, fall back to the official Javadoc URL and mark lower-confidence
3. **Verify against the pin** — confirm the symbol behaves as documented in the pinned version; if docs contradict the codebase or an `instructions/` rule, surface both and let the user choose — never resolve silently
4. **Cite** — record the deep-link URL at the use site and in chat; mark anything unconfirmed as unverified

## Handoffs

- → `@reviewer` — for code review after implementation
- → `debug` skill — if implementation reveals a bug
