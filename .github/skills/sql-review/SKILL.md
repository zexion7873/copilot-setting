---
name: sql-review
description: 'Use when user needs SQL reviewed for injection risks, performance issues, index strategy, or anti-pattern detection. Triggers on: review SQL, SQL review, query review, slow query, check SQL, SQL 審查, 看一下 SQL, 查詢太慢, SQL 效能. Produces severity-classified SQL findings with EXPLAIN guidance. Do NOT use for general code review (prefer code-review), security-only audit (prefer security-audit), or performance tuning beyond SQL (prefer performance).'
---

# SQL Review — Workflow

SQL-focused review. Rules: `instructions/sql.instructions.md`.

**Canonical rules — open the instruction files** (agent mode can read them directly):

- `instructions/sql.instructions.md` — SQL injection, indexing, JDBC resources, MySQL conventions
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

If you cannot open files, Key rules (fallback for agent chat):

- **SQL (JDBC)**: `PreparedStatement` with `?` — zero string concatenation
- **SQL (HQL)**: named parameters (`:param`) — never concatenate into query strings
- **SQL (performance)**: select only needed columns; index WHERE/JOIN columns; no N+1 (query inside loop)

## Phase 1 — Collect SQL

Find all SQL in scope: raw JDBC, HQL, native queries, stored procedures. Include dynamic query construction.

## Phase 2 — Security Check

- [ ] Parameters bound via `?` or `:named` — never concatenated
- [ ] `LIKE` wildcards sanitized
- [ ] No sensitive columns in `SELECT *`

## Phase 3 — Performance Check

- [ ] Only needed columns selected
- [ ] WHERE/JOIN columns likely indexed
- [ ] No functions on indexed columns
- [ ] Large result sets paginated (cursor, not OFFSET)
- [ ] No N+1 pattern (SQL inside loop)

Recommend `EXPLAIN` for queries touching large tables.

## Phase 4 — Report

Classify each finding by severity, then format using the Output Template below.

## Output Template

Per finding:

```
[SEVERITY] <title>
Query: <the SQL or code location>
Issue: <what's wrong>
Fix: <specific remediation>
Impact: <performance/security/correctness>
```

| Severity | Criteria |
|---|---|
| 🔴 CRITICAL | SQL injection; data loss; unbounded DELETE/UPDATE |
| 🟠 MAJOR | Missing index on large table; N+1; `SELECT *` on wide table |
| 🟡 MINOR | Suboptimal pagination; unnecessary columns |
| ⚪ NIT | Alias naming; formatting |

Summary: `Queries reviewed: N | Findings: N critical, N major, N minor, N nit | Top issue: <most impactful>`

### EXPLAIN Cheat Sheet (MySQL)

| Column | Watch for |
|---|---|
| `type` | `ALL` = full scan (bad); `ref`/`range` = index used (good) |
| `key` | `NULL` = no index used |
| `rows` | High number on filtered query = missing index |
| `Extra` | `Using filesort` = ORDER BY not indexed; `Using temporary` = temp table |

## Handoffs

- → `@implementer` — to fix SQL findings
- ← `@reviewer` — SQL review mode activated
- ← `code-review` skill — code review finds SQL issues
