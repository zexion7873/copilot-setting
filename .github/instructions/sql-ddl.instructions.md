---
description: 'Load when writing or reviewing MySQL DDL or migration scripts — CREATE/ALTER TABLE, indexes, stored procedures, backfills. Triggers on: ALTER TABLE, ALGORITHM=INSTANT/INPLACE, online schema change (pt-osc, gh-ost), rollback scripts, chunked backfill, DROP COLUMN, sp_ stored procedures. MySQL 8.0 / InnoDB. Query and JDBC rules: sql.instructions.md.'
applyTo: '**/*.sql'
---

# MySQL DDL & Migration Conventions

Rules for schema changes, migration scripts, and stored procedures. Query / JDBC / HQL rules: `instructions/sql.instructions.md`.

## MySQL DDL & Migrations

Schema conventions — apply to every `CREATE TABLE` / `ALTER TABLE`, not just stored procedures:

- Tables: InnoDB, `utf8mb4`, `created_at` / `updated_at` timestamps mandatory
- FK: `fk_<child>_<parent_col>`; `RESTRICT` default, `CASCADE` only for dependent children
- Index: `idx_<table>_<columns>`

Migration safety — every DDL / data-modifying DML script:

- Every up statement has a down / rollback script; never `DROP TABLE` without explicit sign-off
- Drop a column renamed-then-dropped across two releases; rename a column add-new → dual-write → drop-old — never single-shot
- `ADD COLUMN ... NOT NULL DEFAULT <constant>` is `ALGORITHM=INSTANT` on MySQL 8.0.12+ (metadata-only, safe at any size) — append `, ALGORITHM=INSTANT` so it errors instead of silently rebuilding when INSTANT can't apply (a `STORED` generated column, `ROW_FORMAT=COMPRESSED`, FULLTEXT index, >64 prior instant changes, pre-8.0.29 non-trailing position). Do NOT pre-emptively reach for the nullable → backfill → `MODIFY COLUMN ... NOT NULL` dance: that final `MODIFY` is the genuinely expensive `INPLACE` table rebuild — reserve it for the cases INSTANT rejects. MySQL has no `ALTER COLUMN ... SET NOT NULL`, so `MODIFY` must re-list the full column definition (`DEFAULT` / `COMMENT` / charset) or they are silently dropped
- A large-table `ALTER` that rebuilds the table uses online schema change (pt-osc / gh-ost) or carries an explicit downtime note; index creation uses `ALGORITHM=INPLACE, LOCK=NONE` where supported
- Backfill and long `UPDATE` / `DELETE` are idempotent and chunked by PK range, committed per chunk (low thousands of rows as a starting point — tune per the batch rule in `instructions/sql.instructions.md`)
- Idempotency guards: `CREATE` / `DROP TABLE` take `IF [NOT] EXISTS`, but MySQL has none for `ADD`/`DROP COLUMN` or `CREATE`/`DROP INDEX` — guard those with an `information_schema.COLUMNS` / `STATISTICS` existence check (or rely on the migration tool's version tracking)
- Running-app compatibility: new columns nullable or DB-defaulted so an old app instance's INSERT won't fail; drop columns only after every instance stops reading them; realign `hbm.xml` / DAO with the post-migration schema after deploy

## MySQL Stored Procedures

- Naming: `sp_<action>_<entity>`, snake_case
- Parameters: explicit `IN`/`OUT`/`INOUT`, `p_` prefix, `IN` params first
- Body: `DECLARE EXIT HANDLER FOR SQLEXCEPTION` required; variables `v_` prefix

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| SP without `DECLARE EXIT HANDLER` | Unhandled error; tx unknown state | Add handler with `ROLLBACK; RESIGNAL;` |
| `DROP COLUMN` in the release that stopped writing it | No rollback window; old instances still reading it break | Keep the column one full release, then drop |
| `ADD COLUMN ... NOT NULL DEFAULT 0` treated as a table rewrite | Triggers the slow nullable → backfill → `MODIFY` dance for nothing | `ALGORITHM=INSTANT` on MySQL 8.0.12+ — instant, metadata-only |
| Migration with no down / rollback script | A bad deploy cannot be reversed | Ship a rollback for every up statement |
| `ADD COLUMN` / `CREATE INDEX` guarded with `IF NOT EXISTS` | MySQL has no such guard there — script is not idempotent | Check `information_schema` first, or use the migration tool's tracking |
