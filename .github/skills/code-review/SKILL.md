---
name: code-review
description: 'Use when user wants code reviewed for correctness, style, bugs, and maintainability. Triggers on: review code, code review, check this code, review PR, 審查程式碼, 幫我看程式碼, review 一下, 檢查程式碼. Produces severity-classified findings with a verdict. Do NOT use for security-focused audit (prefer security-audit) or SQL-focused review (prefer sql-review).'
---

# Code Review — Workflow

Structured code review.

**Canonical rules — open the instruction files for the layers you touch** (agent mode can read them directly):

- `instructions/java.instructions.md` — Java 8 language boundary
- `instructions/spring-hibernate.instructions.md` — Spring 3.2 + Hibernate 4.2
- `instructions/sql.instructions.md` — SQL injection, indexing, JDBC resources
- `instructions/security.instructions.md` — OWASP Top 10
- `instructions/jsp.instructions.md` — JSP / JSTL, XSS
- `instructions/xml-config.instructions.md` — Spring XML, hbm.xml, Maven POM
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

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
- [ ] Resources (Connection, InputStream, Session) closed in finally

**Security** (check each):
- [ ] Every SQL query uses bind parameters (`?` or `:named`)
- [ ] Every JSP output wrapped in `<c:out>` or equivalent encoding
- [ ] Every endpoint has explicit access control check
- [ ] No hardcoded credentials, API keys, or secrets

**Performance** (check each):
- [ ] No SQL inside a loop (N+1)
- [ ] No `SELECT *` on wide tables
- [ ] WHERE/JOIN columns have indexes
- [ ] Result sets bounded (LIMIT or pagination)

**Convention** (check each):
- [ ] Java 8 only — no `var`, `List.of()`, records, text blocks
- [ ] Hibernate: `getCurrentSession()` + hbm.xml, no JPA annotations
- [ ] Transactions: `<tx:advice>` only (unless existing `@Transactional` convention)
- [ ] Logging: SLF4J `{}` placeholders, no string concatenation

**Maintainability** (check each):
- [ ] Methods ≤ 30 lines
- [ ] No copy-paste duplication
- [ ] Names self-explanatory; comments explain WHY not WHAT

**POM / Dependencies** (check if `pom.xml` is in scope):
- [ ] No `SNAPSHOT` in release builds; no `LATEST`/`RELEASE` markers
- [ ] Versions centralized in `<dependencyManagement>` — no per-module duplicates
- [ ] Test libs scoped `<scope>test</scope>`; servlet API scoped `provided`
- [ ] Key dependencies (Spring, Hibernate, Jackson, Log4j, Commons) not on known-CVE versions
- [ ] `maven-compiler-plugin` source/target = `1.8`; all plugin versions pinned

## Phase 3 — Classify Findings

| Severity | Definition | Action |
|---|---|---|
| 🔴 CRITICAL | Security vuln, data loss, crash | Must fix before merge |
| 🟠 HIGH | Bug, perf issue, convention violation | Should fix |
| 🟡 MEDIUM | Style, naming, minor improvement | Nice to fix |
| ⚪ LOW | Preference, trivial | Optional |

## Phase 4 — Verdict

Classify all findings, then format using the Output Template below.

## Output Template

Per finding: `[SEVERITY] Category — description @ file:line → suggestion`

```
## Verdict: APPROVE / REQUEST CHANGES / NEEDS DISCUSSION
Findings: N critical, N high, N medium, N low
Summary: <one-sentence assessment>
```

## Handoffs

- → `@implementer` — to fix findings
- → `security-audit` skill — security concerns warrant deeper audit
- → `sql-review` skill — SQL issues warrant dedicated review
- ← `@reviewer` — default activation
