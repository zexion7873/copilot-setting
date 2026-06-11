---
name: sql-review
description: 'Use when user needs SQL reviewed — queries for injection risks, performance, and index strategy, or DDL/DML migration scripts for rollback safety, data-loss risk, lock impact, and backward compatibility. Triggers on: review SQL, SQL review, query review, slow query, check SQL, review migration, schema change, DDL review, ALTER TABLE review, SQL 審查, 看一下 SQL, 查詢太慢, SQL 效能, 看 migration, 審 schema, 看 DDL, 改表審查. Produces severity-classified findings with EXPLAIN, rollback, and lock guidance. Do NOT use for general code review (prefer code-review), security-only audit (prefer security-audit), or initial schema design (prefer plan).'
---

# SQL Review — Workflow

SQL-focused review covering both queries and schema migrations. Rules: `instructions/sql.instructions.md`.

**Canonical rules — open the instruction files** (agent mode can read them directly):

- `instructions/sql.instructions.md` — SQL injection, indexing, JDBC resources, MySQL conventions
- `instructions/spring-hibernate.instructions.md` — Hibernate hbm.xml mappings to re-align after a schema change
- `instructions/xml-config.instructions.md` — hbm.xml structure / conventions
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

## Phase 1 — Collect and Classify

Find all SQL in scope: raw JDBC, HQL, native queries, stored procedures, dynamic query construction, and migration scripts (DDL / data-modifying DML).

Route each statement:

- **Queries** (SELECT / application-level DML) → Phases 2–3
- **Migrations** (CREATE / ALTER / DROP, backfill UPDATE / DELETE / INSERT SELECT) → Phases 4–6. Classify target table size (small <100k rows, medium 100k–10M, large >10M). Ask if unknown. Note migration ordering and inter-statement dependencies.

Skip the phases of the track that has no statements in scope.

## Phase 2 — Check Query Security

- [ ] Parameters bound via `?` or `:named` — never concatenated
- [ ] `LIKE` wildcards sanitized
- [ ] No sensitive columns in `SELECT *`

## Phase 3 — Check Query Performance

- [ ] Only needed columns selected
- [ ] WHERE/JOIN columns likely indexed
- [ ] No functions on indexed columns
- [ ] Large result sets paginated (cursor, not OFFSET)
- [ ] No N+1 pattern (SQL inside loop)

Recommend `EXPLAIN` for queries touching large tables.

## Phase 4 — Verify Migration Rollback Safety

- [ ] Down migration / rollback script exists for every up statement
- [ ] Dropped columns are renamed-then-dropped across two releases (not single-shot)
- [ ] Renames go through add-new + dual-write + drop-old phases
- [ ] No `DROP TABLE` without explicit user sign-off
- [ ] Backfill scripts are idempotent and re-runnable

## Phase 5 — Assess Lock and Downtime Impact

- [ ] `ALTER TABLE` on large tables uses online schema change (pt-osc / gh-ost) or carries explicit downtime note
- [ ] `ADD COLUMN ... NOT NULL DEFAULT <constant>` keeps `ALGORITHM=INSTANT` (MySQL 8.0.12+ default; metadata-only, safe at any size) — append `, ALGORITHM=INSTANT` so it errors instead of silently falling back to a rebuild when INSTANT can't apply (expression/non-constant default, `ROW_FORMAT=COMPRESSED`, FULLTEXT index, >64 prior instant changes, or pre-8.0.29 non-trailing position)
- [ ] Any `MODIFY COLUMN ... NOT NULL` (the real table-rebuilding step) on a large table is flagged for lock impact — it is `INPLACE` but rebuilds the table
- [ ] Index creation uses `ALGORITHM=INPLACE, LOCK=NONE` on MySQL where supported
- [ ] No long-running `UPDATE` / `DELETE` without batching (chunked in 1k–10k rows)

## Phase 6 — Check Running-App Compatibility

For each DDL/DML, answer: "If old app version runs DURING this migration, what breaks?"

- [ ] New columns nullable or have DB default → old app INSERT won't fail
- [ ] Column drops happen AFTER all app instances stop reading/writing
- [ ] FK constraints don't reference columns being altered in same migration
- [ ] `hbm.xml` / DAO aligned with post-migration schema after deploy

If any answer is "old app breaks" → finding is at least HIGH; recommend splitting into multi-release migration.

## Phase 7 — Report

Classify each finding by severity, then format using the Output Template below.

## Output Template

Per finding:

```
[SEVERITY] <title>
Location: <the SQL, code location, or migration ID — file:line>
Issue: <what's wrong or risky>
Fix: <specific remediation, e.g., "split into two releases">
Impact: <performance / security / correctness / data loss / downtime / rollback blocker / compat break>
```

| Severity | Criteria |
|---|---|
| 🔴 CRITICAL | SQL injection; irreversible data loss; unbounded DELETE/UPDATE; production-blocking lock; no rollback path |
| 🟠 HIGH | Missing index on large table; N+1; `SELECT *` on wide table; multi-minute lock on large table; breaks running app instances during deploy |
| 🟡 MEDIUM | Suboptimal pagination; unnecessary columns; backfill not chunked; missing index after column add |
| ⚪ LOW | Alias naming; formatting; column comment missing |

Summary: `Statements reviewed: N | Findings: N critical, N high, N medium, N low | Top issue: <most impactful>`

### EXPLAIN Cheat Sheet (MySQL)

| Column | Watch for |
|---|---|
| `type` | `ALL` = full scan (bad); `ref`/`range` = index used (good) |
| `key` | `NULL` = no index used |
| `rows` | High number on filtered query = missing index |
| `Extra` | `Using filesort` = ORDER BY not indexed; `Using temporary` = temp table |

## Anti-Patterns

- `DROP COLUMN` in same release that stopped writing it — keep removed-but-present for one full release cycle
- Treating `ADD COLUMN ... NOT NULL DEFAULT <constant>` as a table rewrite — on MySQL 8.0.12+ it is `ALGORITHM=INSTANT` (metadata-only, instant at any size). Do NOT pre-emptively switch to the nullable → backfill → `MODIFY COLUMN ... NOT NULL` dance, whose final `MODIFY` is the genuinely expensive `INPLACE` **table rebuild**. Reserve that multi-step path for the cases INSTANT rejects (expression/non-constant default, `ROW_FORMAT=COMPRESSED`, FULLTEXT index, >64 prior instant changes). When `MODIFY` is unavoidable, note MySQL has no `ALTER COLUMN ... SET NOT NULL`, so it must re-list the full column definition (`DEFAULT` / `COMMENT` / charset) or they are dropped
- `UPDATE huge_table SET ...` without `WHERE` + batching — batch with `WHERE id BETWEEN ? AND ?` in 1k–10k chunks
- Renaming a column in one shot — add new column, dual-write, switch reads, drop old over multiple releases
- Migration script that is not idempotent — `CREATE TABLE` / `DROP TABLE` take `IF [NOT] EXISTS`, but MySQL has **no** `IF [NOT] EXISTS` for `ADD`/`DROP COLUMN` or `CREATE`/`DROP INDEX`; guard those with an `information_schema.COLUMNS` / `STATISTICS` existence check (or rely on the migration tool's version tracking), not inline `IF NOT EXISTS`

## Handoffs

- → `@implementer` — to fix SQL or migration findings
- ← `@reviewer` — SQL or migration review mode activated
- ← `code-review` skill — code review finds SQL issues or DAO-side mismatch with a schema change
