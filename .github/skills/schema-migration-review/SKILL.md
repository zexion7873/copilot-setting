---
name: schema-migration-review
description: 'Use when user needs SQL migration scripts (DDL/DML schema changes) reviewed for rollback safety, data-loss risk, lock impact, and backward compatibility. Triggers on: review migration, migration review, schema change, DDL review, ALTER TABLE review, 看 migration, 審 schema, 看 DDL, 改表審查. Produces severity-classified migration findings with rollback and lock guidance. Do NOT use for SELECT query performance (prefer sql-review), application code review (prefer code-review), or initial schema design (prefer plan).'
---

# Schema Migration Review — Workflow

DDL/DML migration review for relational schemas. Companion rules: `instructions/sql.instructions.md`.

**Canonical rules — open the instruction files** (agent mode can read them directly):

- `instructions/sql.instructions.md` — SQL injection, indexing, JDBC resources, MySQL conventions
- `instructions/spring-hibernate.instructions.md` — Hibernate hbm.xml mappings to re-align after a schema change
- `instructions/xml-config.instructions.md` — hbm.xml structure / conventions
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

Focus: rollback safety, data-loss risk, lock duration on production-sized tables, FK and index consistency, and backward compatibility with running app instances during deploy.

## Phase 1 — Inventory the Migration

- List every DDL statement (CREATE / ALTER / DROP) and every data-modifying DML (UPDATE / DELETE / INSERT SELECT).
- For each statement, classify target table size (small <100k rows, medium 100k–10M, large >10M). Ask if unknown.
- Note migration ordering and inter-statement dependencies.

## Phase 2 — Verify Rollback Safety

- [ ] Down migration / rollback script exists for every up statement
- [ ] Dropped columns are renamed-then-dropped across two releases (not single-shot)
- [ ] Renames go through add-new + dual-write + drop-old phases
- [ ] No `DROP TABLE` without explicit user sign-off
- [ ] Backfill scripts are idempotent and re-runnable

## Phase 3 — Assess Lock & Downtime Impact

- [ ] `ALTER TABLE` on large tables uses online schema change (pt-osc / gh-ost) or carries explicit downtime note
- [ ] `ADD COLUMN ... NOT NULL DEFAULT <constant>` keeps `ALGORITHM=INSTANT` (MySQL 8.0.12+ default; metadata-only, safe at any size) — append `, ALGORITHM=INSTANT` so it errors instead of silently falling back to a rebuild when INSTANT can't apply (expression/non-constant default, `ROW_FORMAT=COMPRESSED`, FULLTEXT index, >64 prior instant changes, or pre-8.0.29 non-trailing position)
- [ ] Any `MODIFY COLUMN ... NOT NULL` (the real table-rebuilding step) on a large table is flagged for lock impact — it is `INPLACE` but rebuilds the table
- [ ] Index creation uses `ALGORITHM=INPLACE, LOCK=NONE` on MySQL where supported
- [ ] No long-running `UPDATE` / `DELETE` without batching (chunked in 1k–10k rows)

## Phase 4 — Check Running-App Compatibility

For each DDL/DML, answer: "If old app version runs DURING this migration, what breaks?"

- [ ] New columns nullable or have DB default → old app INSERT won't fail
- [ ] Column drops happen AFTER all app instances stop reading/writing
- [ ] FK constraints don't reference columns being altered in same migration
- [ ] `hbm.xml` / DAO aligned with post-migration schema after deploy

If any answer is "old app breaks" → finding is at least HIGH; recommend splitting into multi-release migration.

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
| 🟠 HIGH | Multi-minute lock on large table; breaks running app instances during deploy |
| 🟡 MEDIUM | Backfill not chunked; missing index after column add |
| ⚪ LOW | Naming convention; column comment missing |

Summary: `Migrations reviewed: N | Findings: N critical, N high, N medium, N low | Top issue: <most impactful>`

## Anti-Patterns

- `DROP COLUMN` in same release that stopped writing it — keep removed-but-present for one full release cycle
- Treating `ADD COLUMN ... NOT NULL DEFAULT <constant>` as a table rewrite — on MySQL 8.0.12+ it is `ALGORITHM=INSTANT` (metadata-only, instant at any size). Do NOT pre-emptively switch to the nullable → backfill → `MODIFY COLUMN ... NOT NULL` dance, whose final `MODIFY` is the genuinely expensive `INPLACE` **table rebuild**. Reserve that multi-step path for the cases INSTANT rejects (expression/non-constant default, `ROW_FORMAT=COMPRESSED`, FULLTEXT index, >64 prior instant changes). When `MODIFY` is unavoidable, note MySQL has no `ALTER COLUMN ... SET NOT NULL`, so it must re-list the full column definition (`DEFAULT` / `COMMENT` / charset) or they are dropped
- `UPDATE huge_table SET ...` without `WHERE` + batching — batch with `WHERE id BETWEEN ? AND ?` in 1k–10k chunks
- Renaming a column in one shot — add new column, dual-write, switch reads, drop old over multiple releases
- Migration script that is not idempotent — `CREATE TABLE` / `DROP TABLE` take `IF [NOT] EXISTS`, but MySQL has **no** `IF [NOT] EXISTS` for `ADD`/`DROP COLUMN` or `CREATE`/`DROP INDEX`; guard those with an `information_schema.COLUMNS` / `STATISTICS` existence check (or rely on the migration tool's version tracking), not inline `IF NOT EXISTS`

## Handoffs

- → `@implementer` — to fix migration findings
- → `sql-review` skill — if the migration's accompanying queries also need review
- ← `@reviewer` — schema migration review mode activated
- ← `code-review` skill — code review uncovers DAO-side mismatch with new schema
