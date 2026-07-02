---
description: 'Load when writing or reviewing SQL — JDBC DAOs, HQL, MySQL DDL/migrations, query tuning. Triggers on: PreparedStatement/? (no concat), :paramName, no SELECT *, WHERE on UPDATE/DELETE, ALTER TABLE, indexes, EXPLAIN, online schema change (INSTANT/INPLACE, pt-osc), rollback scripts, chunked backfills. Raw JDBC, not Spring Boot. Defer Hibernate queries to spring-hibernate.instructions.md.'
applyTo: '**/*.java, **/*.sql, **/*.xml'
---

# SQL Conventions

All SQL — raw JDBC, HQL, native queries. Hibernate queries: `instructions/spring-hibernate.instructions.md`.

## Security

- JDBC: user input via `PreparedStatement` with `?` — zero tolerance for concatenation; HQL/Criteria: named parameters (`:paramName`) only
- Escape `%`, `_`, and the escape char in user input bound to `LIKE` and declare it: `LIKE ? ESCAPE '\\'`; never silently strip wildcards
- No `SELECT *` on tables with sensitive columns; never log SQL with credentials or PII

## Performance

- No `SELECT *` — list columns
- No functions on indexed columns in `WHERE` — use ranges
- No `OFFSET` pagination on large tables — cursor: `WHERE id > ? ORDER BY id LIMIT N`
- N+1 = SQL inside a loop — batch with `IN` or JOIN
- `IN` vs `EXISTS`: MySQL 8.0 semijoin-optimizes both (`EXISTS` since 8.0.16) — pick the clearer, check `EXPLAIN`; `NOT IN` matches nothing if the subquery returns `NULL`
- Batch DML, never row-by-row; chunk + commit per chunk to bound locks, tx size, binlog (low thousands is a tuning start, not a limit)

## JDBC Resources

- `try-with-resources` for `Connection`/`PreparedStatement`/`ResultSet`
- `WHERE` mandatory on every `UPDATE`/`DELETE`
- Raw-JDBC transactions (Spring `<tx:advice>` covers managed code): commit or rollback on every path

## MySQL DDL & Migrations

Schema — every `CREATE TABLE`/`ALTER TABLE`: InnoDB, `utf8mb4`, `created_at`/`updated_at` mandatory; FK `fk_<child>_<parent_col>` (`RESTRICT` default, `CASCADE` only for dependent children); index `idx_<table>_<columns>`.

Migration safety:

- Every up has a down/rollback; never `DROP TABLE` without explicit sign-off
- Expand-contract: drop = rename-then-drop over two releases; rename = add-new → dual-write → drop-old; never single-shot
- `ADD COLUMN ... NOT NULL DEFAULT <constant>`: `ALGORITHM=INSTANT` on MySQL 8.0.12+ (metadata-only, any size) — append `, ALGORITHM=INSTANT` to fail loudly instead of silently rebuilding when INSTANT can't apply (`STORED` generated column, `ROW_FORMAT=COMPRESSED`, FULLTEXT, >64 prior instant changes, pre-8.0.29 non-trailing position). Don't default to nullable → backfill → `MODIFY ... NOT NULL` — that `MODIFY` is the expensive `INPLACE` rebuild, only for cases INSTANT rejects; no `ALTER COLUMN ... SET NOT NULL` in MySQL, so `MODIFY` must re-list the full definition (`DEFAULT`/`COMMENT`/charset) or they're silently dropped
- Large-table rebuilding `ALTER`: pt-osc/gh-ost or explicit downtime note; index creation `ALGORITHM=INPLACE, LOCK=NONE` where supported
- Backfills and long `UPDATE`/`DELETE`: idempotent, chunked by PK range, committed per chunk
- `IF [NOT] EXISTS` exists only for `CREATE`/`DROP TABLE` — not `ADD`/`DROP COLUMN` or `CREATE`/`DROP INDEX`; guard with `information_schema.COLUMNS`/`STATISTICS` or the migration tool's tracking
- Running-app compat: new columns nullable or DB-defaulted (old instances' INSERTs must not fail); drop only after no instance reads them; realign `hbm.xml`/DAO post-deploy

## MySQL Stored Procedures

`sp_<action>_<entity>`, snake_case; params explicit `IN`/`OUT`/`INOUT`, `p_` prefix, `IN` first; variables `v_` prefix; `DECLARE EXIT HANDLER FOR SQLEXCEPTION` required.

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `"WHERE name = '" + name + "'"` | SQL injection | `PreparedStatement` with `?` |
| `WHERE YEAR(created_at) = 2024` | Function kills index | `>= '2024-01-01' AND < '2025-01-01'` |
| `LIMIT 10 OFFSET 10000` | Scans 10K rows to discard | Cursor: `WHERE id > ? ORDER BY id LIMIT 10` |
| `DROP COLUMN` in the release that stopped writing it | Old instances still read it | Keep one full release, then drop |
| `ADD COLUMN`/`CREATE INDEX` with `IF NOT EXISTS` | No such guard in MySQL | Check `information_schema` first |
