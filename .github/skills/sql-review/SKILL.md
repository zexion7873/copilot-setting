---
name: sql-review
description: 'Use when user asks to review SQL, optimize a query, analyze an execution plan, check for SQL injection, or improve database performance. Also triggers on: 看一下這段 SQL, 查詢太慢, 效能優化, SQL 審查, 有沒有 injection. Covers injection prevention, index strategy, anti-pattern detection, and optimization. Do NOT use for writing new SQL from scratch or general Java code review that happens to contain SQL strings.'
context: fork
---

# SQL Review — Workflow

Process for reviewing SQL. Rules live in `instructions/sql-rules.instructions.md`. Workflow output format lives in `prompts/sql-review.prompt.md`. This file defines the order of attack.

## Phase 1 — Inventory

Locate every SQL site before judging any of them.

```bash
grep -rn "SELECT\|INSERT\|UPDATE\|DELETE\|CREATE\|ALTER\|DROP" --include="*.java" src/
find . -name "*.sql" -not -path "*/target/*"
grep -rn "SELECT\|INSERT\|UPDATE\|DELETE" --include="*.xml" src/
```

For each query record: file:line, statement type, parameterization status, caller.

## Phase 2 — Security First

A slow query is a problem; an injectable query is a crisis. Triage security before performance.

```bash
# Injection candidates — string concatenation in SQL
grep -rn '"SELECT.*".*+\|"WHERE.*".*+' --include="*.java" src/
grep -rn 'String\.format.*SELECT\|String\.format.*WHERE' --include="*.java" src/
grep -rn '\.append.*WHERE\|\.append.*AND' --include="*.java" src/

# Statement (not PreparedStatement) usage
grep -rn "createStatement()\|Statement [a-z]" --include="*.java" src/
```

Flag every concatenated SQL site as CRITICAL until proven safe (e.g., constant-only).

## Phase 3 — Performance

Run EXPLAIN before recommending anything. Guessing is forbidden.

```sql
-- MySQL 8+
EXPLAIN ANALYZE <query>;

-- PostgreSQL
EXPLAIN (ANALYZE, BUFFERS) <query>;
```

EXPLAIN signal cheat sheet:

| Signal | Meaning | Likely fix |
|---|---|---|
| `type: ALL` / `Seq Scan` | Full table scan | Add index on filter column |
| `Using filesort` | Sort without index | Add index on ORDER BY column |
| `Using temporary` | Temp table built | Rewrite or add covering index |
| `rows` >> actual | Stale statistics | `ANALYZE TABLE` |
| Nested loop on big tables | Bad join order | Check join column indexes |

## Phase 4 — Anti-Pattern Scan

Grep these patterns across the codebase:

| Anti-pattern | Pattern | Action |
|---|---|---|
| SQL injection | `"SELECT.*" +` | PreparedStatement with `?` |
| `SELECT *` | `SELECT \*` | List columns |
| N+1 | SQL inside loop | Batch with `IN` or JOIN |
| Unbounded write | `UPDATE`/`DELETE` without `WHERE` | Add `WHERE` |
| DISTINCT masking | `SELECT DISTINCT` with multi-JOIN | Fix JOIN |
| Function in WHERE | `WHERE YEAR(/UPPER(/DATE(` | Range condition |
| OFFSET on large | `LIMIT \d+ OFFSET \d+` | Cursor pagination |
| Correlated subquery | `WHERE x = (SELECT ... outer.col)` | JOIN or window function |
| Unbounded SELECT | SELECT in app code without LIMIT | Add LIMIT / paginate |

## Phase 5 — Code Quality

Lower priority but still part of the pass:

- Table aliases meaningful (`u` for users, `o` for orders)
- One clause per line, SQL keywords UPPER
- PK is INT/BIGINT, not VARCHAR
- Money is DECIMAL(p,s), never FLOAT
- NOT NULL where it should be
- FK constraints defined (or omission justified)
- try-with-resources for Connection/PreparedStatement/ResultSet
- Transactions commit/rollback on every path
- Batch size bounded (500-1000) for bulk ops

## Output Format

For each finding:

```
[SEVERITY] [Category] — Title
  Location: <file>#<method>:<line>
  Problem: <what + impact>
  Fix: <specific code/index change>
  Verify: <how to confirm (EXPLAIN diff, test case)>
```

Severity: `CRITICAL` (security / data loss) / `HIGH` (perf, >1s queries) / `MEDIUM` (perf, scaling risk) / `LOW` (style).

End the report with: counts by severity, top 3 priority actions, scores (1-10) for Security / Performance / Maintainability.

## Workflow Anti-Patterns

- Reviewing without EXPLAIN → always pull a plan first
- Adding indexes without checking write cost → confirm write frequency
- Fixing SQL while ignoring the Java caller → trace DAO → caller
- Treating style issues as critical → severity must reflect real impact
- Skipping Phase 2 → injection slips through
