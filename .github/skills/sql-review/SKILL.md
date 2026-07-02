---
name: sql-review
description: 'Use when user needs SQL reviewed — queries for injection risks, performance, and index strategy, or DDL/DML migration scripts for rollback safety, lock impact, and backward compatibility. Triggers on: review SQL, slow query, review migration, schema change, SQL 審查, 查詢太慢, 審 schema. Produces severity-classified findings with EXPLAIN, rollback, and lock guidance. Do NOT use for general code review (prefer code-review), security-only audit (prefer security-audit), or initial schema design (prefer plan).'
---

# SQL Review — Workflow

SQL-focused review covering both queries and schema migrations. Rules: `instructions/sql.instructions.md`.

## Phase 0 — Load canonical rules

Before reporting findings, open the instruction files for the SQL under review — glob auto-loading does not fire for files you read mid-task (these files are the canonical SQL and mapping rules): `instructions/sql.instructions.md`, `instructions/spring-hibernate.instructions.md`, `instructions/xml-config.instructions.md`, `instructions/no-heredoc.instructions.md`.

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

Check each migration against the rollback rules in `instructions/sql.instructions.md` (`MySQL DDL & Migrations`); flag every violation:

- [ ] Down migration / rollback script exists for every up statement
- [ ] Dropped columns are renamed-then-dropped across two releases (not single-shot)
- [ ] Renames go through add-new + dual-write + drop-old phases
- [ ] No `DROP TABLE` without explicit user sign-off
- [ ] Backfill scripts are idempotent and re-runnable

## Phase 5 — Assess Lock and Downtime Impact

Check each statement against the DDL / migration safety rules in `instructions/sql.instructions.md` (`MySQL DDL & Migrations`); flag every violation:

- [ ] Large-table `ALTER` uses online schema change (pt-osc / gh-ost) or carries a downtime note
- [ ] `ADD COLUMN ... NOT NULL DEFAULT <constant>` is INSTANT, not a table rewrite (`instructions/sql.instructions.md`)
- [ ] Table-rebuilding `MODIFY COLUMN` on a large table is flagged for lock impact
- [ ] Index creation uses `ALGORITHM=INPLACE, LOCK=NONE` where supported
- [ ] Long `UPDATE` / `DELETE` is chunked by PK range, committed per chunk

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

Canonical DDL / migration anti-patterns live in `instructions/sql.instructions.md` (`MySQL DDL & Migrations` plus its Anti-Patterns table). In review, watch especially for:

- `DROP COLUMN` in the release that stopped writing it
- `ADD COLUMN ... NOT NULL DEFAULT` treated as a table rewrite
- Single-shot column rename
- Non-idempotent migration (false `IF NOT EXISTS` on `ADD`/`DROP COLUMN`, `CREATE`/`DROP INDEX`)
- Unbatched `UPDATE` / `DELETE` on a huge table

## Handoffs

- → `@implementer` — to fix SQL or migration findings
