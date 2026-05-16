---
agent: 'agent'
description: 'SQL review output format and EXPLAIN cheat sheet. Pairs with skills/sql-review/SKILL.md (workflow).'
---

# SQL Review Output Format

Output format for the `sql-review` skill. Workflow: `skills/sql-review/SKILL.md`. SQL rules: `instructions/sql.instructions.md`.

## Finding Format

For each SQL issue found:

```
[SEVERITY] <title>
Query: <the SQL or code location>
Issue: <what's wrong>
Fix: <specific remediation>
Impact: <performance/security/correctness>
```

## Severity

| Severity | Criteria |
|---|---|
| 🔴 CRITICAL | SQL injection; data loss; unbounded DELETE/UPDATE |
| 🟠 MAJOR | Missing index on large table; N+1; `SELECT *` on wide table |
| 🟡 MINOR | Suboptimal pagination; unnecessary columns; style |
| ⚪ NIT | Alias naming; formatting |

## EXPLAIN Cheat Sheet (MySQL)

| Column | Watch for |
|---|---|
| `type` | `ALL` = full scan (bad); `ref`/`range` = index used (good) |
| `key` | `NULL` = no index used |
| `rows` | High number on filtered query = missing index |
| `Extra` | `Using filesort` = ORDER BY not indexed; `Using temporary` = temp table created |

### Quick interpretation

- `type=ALL` + high `rows` → add index on WHERE columns
- `Using filesort` → add index covering ORDER BY
- `Using temporary` → simplify GROUP BY or add composite index
- `key=NULL` on JOIN → add index on join column

## Summary Format

```
## SQL Review Summary
Queries reviewed: N
Findings: N critical, N major, N minor, N nit
Top issue: <most impactful finding>
```
