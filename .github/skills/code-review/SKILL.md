---
name: code-review
description: 'Use when user wants code reviewed for correctness, style, bugs, and maintainability. Triggers on: review code, code review, check this code, check PR, review PR, review this, 審查程式碼, 幫我看程式碼, review 一下, 檢查程式碼. Produces severity-classified findings with a verdict. Do NOT use for security-focused audit (prefer security-audit) or SQL-focused review (prefer sql-review).'
---

# Code Review — Workflow

Structured code review.

## Phase 0 — Load canonical rules

**Canonical rules — open the instruction files for the layers you touch** (agent mode can read them directly):

- `instructions/java.instructions.md` — Java 8 language boundary
- `instructions/spring-hibernate.instructions.md` — Spring 3.2 + Hibernate 4.2
- `instructions/sql.instructions.md` — SQL injection, indexing, JDBC resources
- `instructions/security.instructions.md` — OWASP Top 10
- `instructions/jsp.instructions.md` — JSP / JSTL, XSS
- `instructions/xml-config.instructions.md` — Spring XML, hbm.xml, Maven POM
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection
- `instructions/testing.instructions.md` — test conventions (test-class `@Transactional` auto-rollback is sanctioned)

Read-back receipt (required): before leaving this step, NAME each instruction file you opened above and QUOTE the single most load-bearing rule from each that applies to this change — a generic restatement proves you did not open it.

## Phase 1 — Understand the Change

1. Read the diff / files under review
2. Understand the intent: what problem does this solve?
3. Check if the approach matches existing patterns

## Phase 2 — Review by Category

**Correctness** (check each):
- [ ] Null/empty inputs handled at method entry
- [ ] Off-by-one: loop bounds, substring, index access
- [ ] Edge cases: zero, negative, empty collection, max-size
- [ ] Shared mutable state accessed from multiple threads → synchronized or thread-local?
- [ ] JDBC resources (`Connection`, `PreparedStatement`, `ResultSet`, streams) managed via try-with-resources; Hibernate `Session` from `getCurrentSession()` is never closed/flushed manually (Spring owns its lifecycle)

**Security** (check each):
- [ ] Every SQL query uses bind parameters (`?` or `:named`)
- [ ] Every JSP output wrapped in `<c:out>` or equivalent encoding
- [ ] Every endpoint has explicit access control check
- [ ] No hardcoded credentials, API keys, or secrets

**Performance** (check each):
- [ ] No SQL inside a loop (N+1)
- [ ] No `SELECT *` — columns listed explicitly
- [ ] WHERE/JOIN columns have indexes
- [ ] Result sets bounded (LIMIT or pagination)

**Convention** (check each):
- [ ] Java 8 only — no `var`, `List.of()`, records, text blocks
- [ ] Hibernate: `getCurrentSession()` + hbm.xml, no JPA annotations
- [ ] Transactions: production code uses `<tx:advice>` only (unless existing `@Transactional` convention); `@Transactional` on a test class for auto-rollback is sanctioned (`instructions/testing.instructions.md`)
- [ ] Logging: SLF4J `{}` placeholders, no string concatenation

**Maintainability** (check each):
- [ ] Each method does one thing (~30+ lines of logic is a smell to check, not a hard limit)
- [ ] No copy-paste duplication
- [ ] Names self-explanatory; comments explain WHY not WHAT

**POM / Dependencies** (check if `pom.xml` is in scope):
- [ ] No `SNAPSHOT` in release builds; no `LATEST`/`RELEASE` markers
- [ ] Versions centralized in `<dependencyManagement>` — no per-module duplicates
- [ ] Test libs scoped `<scope>test</scope>`; servlet API scoped `provided`
- [ ] Non-framework dependencies (Jackson, Log4j, Commons, …) not on known-CVE versions — the pinned Spring 3.2 / Hibernate 4.2 carry unpatched CVEs documented as baseline risk (`instructions/security.instructions.md`), not a per-PR finding
- [ ] `maven-compiler-plugin` source/target = `1.8`; all plugin versions pinned

## Phase 3 — Classify Findings

| Severity | Definition | Action |
|---|---|---|
| 🔴 CRITICAL | Security vuln, data loss, crash | Must fix before merge |
| 🟠 HIGH | Bug, perf issue, convention violation | Should fix |
| 🟡 MEDIUM | Style, naming, minor improvement | Nice to fix |
| ⚪ LOW | Preference, trivial | Optional |

## Phase 4 — Require Build & Test Evidence

The reviewer is read-only and does not run the build itself — require the author to supply it.

Before rendering a verdict, confirm fresh evidence that the change builds and tests pass:

- [ ] Actual `mvn` output is present in the PR / change context (e.g. `mvn -q clean verify`, or at least `compile` + `test`)
- [ ] The evidence reflects the **current** revision under review — not a stale run from before the latest change
- [ ] Tests covering the change actually ran (not skipped, no `-DskipTests`)

If build/test evidence is missing or stale, you **cannot** APPROVE — render REQUEST CHANGES (or NEEDS DISCUSSION) and ask the author to attach fresh `mvn` output. Never infer a passing build from reading the diff.

## Phase 5 — Render Verdict

Classify all findings, then format using the Output Template below.

APPROVE requires ALL of:

- Zero unresolved 🔴 CRITICAL or 🟠 HIGH findings
- Fresh build & test evidence for the current revision (Phase 4)
- No outstanding Java 8 / `<tx:advice>` / N+1 convention violations from Phase 2

Otherwise render REQUEST CHANGES or NEEDS DISCUSSION.

## Output Template

Per finding: `[SEVERITY] Category — description @ file:line → suggestion`

```
## Verdict: APPROVE / REQUEST CHANGES / NEEDS DISCUSSION
Findings: N critical, N high, N medium, N low
Evidence: <mvn command + result, or "MISSING — fresh build/test output required">
Summary: <one-sentence assessment>
```

## Handoffs

- → `@implementer` — to fix findings
- → `security-audit` skill — security concerns warrant deeper audit
- → `sql-review` skill — SQL issues or migration / DDL changes warrant dedicated review
- ← `@reviewer` — default activation
