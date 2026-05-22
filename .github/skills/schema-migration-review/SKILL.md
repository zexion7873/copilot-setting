---
name: schema-migration-review
description: 'Use when user needs SQL migration scripts (DDL/DML schema changes) reviewed for rollback safety, data-loss risk, lock impact, and backward compatibility. Triggers on: review migration, migration review, schema change, DDL review, ALTER TABLE review, 看 migration, 審 schema, 看 DDL, 改表審查. Produces severity-classified migration findings with rollback and lock guidance. Do NOT use for SELECT query performance (prefer sql-review), application code review (prefer code-review), or initial schema design (prefer plan or sdd).'
---

# Schema Migration Review — Workflow

DDL/DML migration review for relational schemas. Companion rules: `instructions/sql.instructions.md`.

**Canonical rules — open the instruction files** (agent mode can read them directly):

- `instructions/sql.instructions.md` — SQL injection, indexing, JDBC resources, MySQL conventions
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

If you cannot open files, Key rules (fallback for agent chat):

- **SQL (DML safety)**: parameterize with `?` / `:named`; batch large `UPDATE` / `DELETE`; never unbounded writes
- **SQL (DDL safety)**: online schema change on large tables; new columns nullable or DB-default
- **SQL (JDBC/HQL)**: `?` placeholders or named parameters — zero string concatenation

Focus: rollback safety, data-loss risk, lock duration on production-sized tables, FK and index consistency, and backward compatibility with running app instances during deploy.

## Phase 1 — Inventory the Migration

- List every DDL statement (CREATE / ALTER / DROP) and every data-modifying DML (UPDATE / DELETE / INSERT SELECT).
- For each statement, classify target table size (small <100k rows, medium 100k–10M, large >10M). Ask if unknown.
- Note migration ordering and inter-statement dependencies.

## Phase 2 — Rollback Safety

- [ ] Down migration / rollback script exists for every up statement
- [ ] Dropped columns are renamed-then-dropped across two releases (not single-shot)
- [ ] Renames go through add-new + dual-write + drop-old phases
- [ ] No `DROP TABLE` without explicit user sign-off
- [ ] Backfill scripts are idempotent and re-runnable

## Phase 3 — Lock & Downtime Impact

- [ ] `ALTER TABLE` on large tables uses online schema change (pt-osc / gh-ost) or carries explicit downtime note
- [ ] No `ALTER TABLE ... ADD COLUMN ... NOT NULL DEFAULT <expr>` on large tables (rewrites whole table)
- [ ] Index creation uses `ALGORITHM=INPLACE, LOCK=NONE` on MySQL where supported
- [ ] No long-running `UPDATE` / `DELETE` without batching (chunked in 1k–10k rows)

## Phase 4 — Compatibility With Running App

- [ ] New columns are nullable or have DB-level default — running old app instances won't fail INSERT
- [ ] Column drops happen AFTER all app instances stop reading/writing them
- [ ] FK constraints don't reference soon-to-be-changed columns
- [ ] Application's `hbm.xml` / DAO matches new schema after deploy

## Phase 5 — Report

Classify each finding by severity, then format using the Output Template below.

## Output Template

Per finding:

```
[SEVERITY] <title>
Statement: <DDL/DML location — file:line or migration ID>
Issue: <what's risky>
Impact: <data loss / downtime / rollback blocker / compat break>
Fix: <specific remediation, e.g., "split into two releases">
```

| Severity | Criteria |
|---|---|
| 🔴 CRITICAL | Irreversible data loss; production-blocking lock; no rollback path |
| 🟠 MAJOR | Multi-minute lock on large table; breaks running app instances during deploy |
| 🟡 MINOR | Backfill not chunked; missing index after column add |
| ⚪ NIT | Naming convention; column comment missing |

Summary: `Migrations reviewed: N | Findings: N critical, N major, N minor, N nit | Top issue: <most impactful>`

## Anti-Patterns

- `DROP COLUMN` in same release that stopped writing it — keep removed-but-present for one full release cycle
- `ALTER TABLE ... ADD COLUMN NOT NULL DEFAULT '...'` on a 10M-row table — add nullable, backfill in chunks, then `SET NOT NULL`
- `UPDATE huge_table SET ...` without `WHERE` + batching — batch with `WHERE id BETWEEN ? AND ?` in 1k–10k chunks
- Renaming a column in one shot — add new column, dual-write, switch reads, drop old over multiple releases
- Migration script that is not idempotent — wrap creates with `IF NOT EXISTS`, drops with `IF EXISTS`

## Handoffs

- → `@implementer` — to fix migration findings
- → `sql-review` skill — if the migration's accompanying queries also need review
- ← `@reviewer` — schema migration review mode activated
- ← `code-review` skill — code review uncovers DAO-side mismatch with new schema
