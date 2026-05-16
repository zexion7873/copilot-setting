---
name: code-review
description: 'Use when user wants code reviewed for correctness, style, bugs, and maintainability. Triggers on: review code, code review, check this code, review PR, 審查程式碼, 幫我看程式碼, review 一下, 檢查程式碼. Produces severity-classified findings with a verdict. Do NOT use for security-focused audit (prefer security-audit), SQL-focused review (prefer sql-review), or SDD review (prefer sdd-review).'
---

# Code Review — Workflow

Structured code review.

Full coding rules in `instructions/*.instructions.md`. Key rules:

- **Java 8 only**: no 9+ syntax — see `instructions/java.instructions.md`
- **Hibernate/Spring**: `getCurrentSession()`, `<tx:advice>`, no annotations, no `@RestController` — see `instructions/spring-hibernate.instructions.md`
- **SQL**: parameterized only — see `instructions/sql.instructions.md`
- **Security**: OWASP essentials — see `instructions/security.instructions.md`

## Phase 1 — Understand the Change

1. Read the diff / files under review
2. Understand the intent: what problem does this solve?
3. Check if the approach matches existing patterns

## Phase 2 — Review by Category

**Correctness**: logic errors, off-by-one, null handling, edge cases (empty collections, zero values), concurrency (shared mutable state), resource leaks (unclosed connections)

**Security**: SQL injection (all queries parameterized?), XSS (all JSP output encoded?), auth (access control on every endpoint?), secrets (no hardcoded credentials?)

**Performance**: N+1 queries (SQL inside loops)? `SELECT *` or missing indexes? Unbounded result sets? Expensive ops in hot paths?

**Convention Compliance**: Java 8 only? `getCurrentSession()` + hbm.xml + no JPA? `<tx:advice>` only, no `@Transactional`? SLF4J parameterized? Proper exception hierarchy?

**Maintainability**: clear naming? No duplication? Methods ≤30 lines? Comments explain WHY?

## Phase 3 — Classify Findings

| Severity | Definition | Action |
|---|---|---|
| 🔴 CRITICAL | Security vuln, data loss, crash | Must fix before merge |
| 🟠 MAJOR | Bug, perf issue, convention violation | Should fix |
| 🟡 MINOR | Style, naming, minor improvement | Nice to fix |
| ⚪ NIT | Preference, trivial | Optional |

## Phase 4 — Verdict

```
## Verdict: APPROVE / REQUEST CHANGES / NEEDS DISCUSSION
Findings: N critical, N major, N minor, N nit
Summary: <one-sentence assessment>
```

Per finding: `[SEVERITY] Category — description @ file:line → suggestion`

## Handoffs

- → `@implementer` — to fix findings
- → `security-audit` skill — security concerns warrant deeper audit
- → `sql-review` skill — SQL issues warrant dedicated review
- ← `@reviewer` — default activation
