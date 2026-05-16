---
name: sql-review
description: 'Use when user needs SQL reviewed for injection risks, performance issues, index strategy, or anti-pattern detection. Triggers on: review SQL, SQL review, query review, slow query, check SQL, SQL 審查, 看一下 SQL, 查詢太慢, SQL 效能. Produces severity-classified SQL findings with EXPLAIN guidance. Do NOT use for general code review (prefer code-review), security-only audit (prefer security-audit), or performance tuning beyond SQL (prefer performance).'
---

# SQL Review — Workflow

SQL-focused review. Rules: `instructions/sql.instructions.md`. Output format: `prompts/sql-review-output.prompt.md`.

Full coding rules in `instructions/*.instructions.md`. Key rules:

- **Injection**: `PreparedStatement` with `?` only — zero concatenation
- **Performance**: no `SELECT *`, no functions on indexed columns, cursor pagination
- **Resources**: `try-with-resources` for JDBC — see `instructions/sql.instructions.md`
- **Hibernate**: named params in HQL — see `instructions/spring-hibernate.instructions.md`

## Security Checks

- Parameters bound via `?` or `:named` — never concatenated
- `LIKE` wildcards sanitized
- No sensitive columns in `SELECT *`

## Performance Checks

- Only needed columns selected
- WHERE/JOIN columns likely indexed
- No functions on indexed columns
- Large result sets paginated (cursor, not OFFSET)
- No N+1 (SQL inside loop)
- Recommend `EXPLAIN` for queries on large tables

## Severity

| Level | Criteria |
|---|---|
| 🔴 CRITICAL | SQL injection; data loss; unbounded DELETE/UPDATE |
| 🟠 MAJOR | Missing index on large table; N+1; `SELECT *` on wide table |
| 🟡 MINOR | Suboptimal pagination; unnecessary columns |
| ⚪ NIT | Alias naming; formatting |

## Output

Use format from `prompts/sql-review-output.prompt.md`.

## Handoffs

- → `@implementer` — to fix SQL findings
- ← `@reviewer` — SQL review mode activated
- ← `code-review` skill — code review finds SQL issues
