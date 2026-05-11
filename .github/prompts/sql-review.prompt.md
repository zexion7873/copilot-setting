---
agent: 'agent'
tools: ['search/changes', 'search/codebase', 'edit/editFiles', 'read/problems']
description: 'SQL review workflow for ${selection}. Applies rules from instructions/sql-rules.instructions.md. Works across MySQL, PostgreSQL, SQL Server, Oracle.'
---

# SQL Review

Review and optimize `${selection}` (or the entire project if no selection). Apply rules from `instructions/sql-rules.instructions.md`. This prompt defines the review workflow and output format only.

## Workflow

1. **Inventory** — Locate every SQL site:
   ```bash
   grep -rn "SELECT\|INSERT\|UPDATE\|DELETE" --include="*.java" src/
   find . -name "*.sql" -not -path "*/target/*"
   ```
2. **Security pass** — Flag every concatenated SQL site as CRITICAL until proven safe.
3. **EXPLAIN pass** — Run `EXPLAIN ANALYZE` (MySQL 8+) or `EXPLAIN (ANALYZE, BUFFERS)` (PostgreSQL) on candidates flagged by the rules.
4. **Anti-pattern scan** — Apply rules from `sql-rules.instructions.md` (SELECT *, function in WHERE, OFFSET on large, N+1, missing WHERE on UPDATE/DELETE, etc.).
5. **Recommend** — Output findings per the format below.

## EXPLAIN Signal Cheat Sheet

| Signal | Meaning | Likely fix |
|---|---|---|
| `type: ALL` / `Seq Scan` | Full table scan | Add index on filter column |
| `Using filesort` | Sort without index | Add index on ORDER BY column |
| `Using temporary` | Temp table built | Rewrite or add covering index |
| `rows` >> actual | Stale statistics | `ANALYZE TABLE` |
| Nested loop on big tables | Bad join order | Check join column indexes |

## Output Format

For each issue:

```
[SEVERITY] [Category] — Brief description
  Location: <table/view/procedure>:<line>
  Problem: <what is wrong + impact>
  Fix: <specific recommendation with code>
```

Severity: `CRITICAL` (security / data loss) / `WARNING` (performance, maintainability) / `SUGGESTION` (style).

End with: counts by severity, top 3 priority actions, and an EXPLAIN / execution-plan recommendation when performance issues are flagged.
