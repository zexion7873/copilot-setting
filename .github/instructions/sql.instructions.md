---
description: 'Load when writing or reviewing SQL — JDBC DAOs, HQL, MySQL DDL/migrations, query tuning. Triggers on: PreparedStatement/? (no concat), :paramName, no SELECT *, WHERE on UPDATE/DELETE, ALTER TABLE, indexes, EXPLAIN, online schema change (INSTANT/INPLACE, pt-osc), rollback scripts, chunked backfills. Raw JDBC, not Spring Boot. Defer Hibernate queries to spring-hibernate.instructions.md.'
applyTo: '**/*.java, **/*.sql, **/*.hbm.xml'
---

# SQL Conventions

Non-negotiable rules for all SQL — raw JDBC, HQL, native queries. Hibernate query patterns: `instructions/spring-hibernate.instructions.md`.

## Security

- **JDBC**: all user input via `PreparedStatement` with `?` — zero tolerance for string concatenation
- **HQL / Criteria**: use named parameters (`:paramName`) only — never concatenate into query strings
- Escape `%`, `_`, and the escape char itself in any user input bound to `LIKE`, and declare it — `... LIKE ? ESCAPE '\\'`; never silently strip user-supplied wildcards (that changes query semantics)
- No `SELECT *` on tables with sensitive columns
- Never log SQL containing credentials or PII

## Performance

- No `SELECT *` — list columns explicitly
- No functions on indexed columns in `WHERE` — use range conditions
- No `OFFSET` pagination on large tables — cursor: `WHERE id > ? ORDER BY id LIMIT N`
- N+1 = SQL inside a loop — batch with `IN` or JOIN
- `IN` vs `EXISTS` subqueries: MySQL 8.0 optimizes both with the same semijoin transforms (`EXISTS` since 8.0.16) — pick the clearer form and check `EXPLAIN`; beware `NOT IN` matching nothing when the subquery returns a `NULL`
- Batch INSERT/UPDATE/DELETE — never row-by-row; chunk and commit per chunk to bound lock time, transaction size, and redo/binlog volume (low thousands of rows is a typical starting point, not a fixed limit — tune to row width, index count, and lock/replication pressure)

## JDBC Resources

- `try-with-resources` for `Connection`, `PreparedStatement`, `ResultSet`
- `WHERE` clause mandatory on every `UPDATE` and `DELETE`
- Transactions (raw JDBC only — Spring-managed `<tx:advice>` handles this automatically): commit or rollback on every code path

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
- Backfill and long `UPDATE` / `DELETE` are idempotent and chunked by PK range, committed per chunk (size per the Performance batch rule above)
- Idempotency guards: `CREATE` / `DROP TABLE` take `IF [NOT] EXISTS`, but MySQL has none for `ADD`/`DROP COLUMN` or `CREATE`/`DROP INDEX` — guard those with an `information_schema.COLUMNS` / `STATISTICS` existence check (or rely on the migration tool's version tracking)
- Running-app compatibility: new columns nullable or DB-defaulted so an old app instance's INSERT won't fail; drop columns only after every instance stops reading them; realign `hbm.xml` / DAO with the post-migration schema after deploy

## MySQL Stored Procedures

- Naming: `sp_<action>_<entity>`, snake_case
- Parameters: explicit `IN`/`OUT`/`INOUT`, `p_` prefix, `IN` params first
- Body: `DECLARE EXIT HANDLER FOR SQLEXCEPTION` required; variables `v_` prefix

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `"WHERE name = '" + name + "'"` | SQL injection | `PreparedStatement` with `?` + `setString()` |
| `SELECT * FROM orders` | Unnecessary columns; schema-fragile | List columns explicitly |
| `WHERE YEAR(created_at) = 2024` | Function kills index | Range: `>= '2024-01-01' AND < '2025-01-01'` |
| `LIMIT 10 OFFSET 10000` | Scans 10K rows to discard | Cursor: `WHERE id > ? ORDER BY id LIMIT 10` |
| SQL inside a `for` loop | N+1 queries | `WHERE id IN (?, ...)` or JOIN |
| `Connection` without try-with-resources | Leak on exception; pool exhaustion | `try (Connection c = ...) { }` |
| SP without `DECLARE EXIT HANDLER` | Unhandled error; tx unknown state | Add handler with `ROLLBACK; RESIGNAL;` |
| `DROP COLUMN` in the release that stopped writing it | No rollback window; old instances still reading it break | Keep the column one full release, then drop |
| `ADD COLUMN ... NOT NULL DEFAULT 0` treated as a table rewrite | Triggers the slow nullable → backfill → `MODIFY` dance for nothing | `ALGORITHM=INSTANT` on MySQL 8.0.12+ — instant, metadata-only |
| Migration with no down / rollback script | A bad deploy cannot be reversed | Ship a rollback for every up statement |
| `ADD COLUMN` / `CREATE INDEX` guarded with `IF NOT EXISTS` | MySQL has no such guard there — script is not idempotent | Check `information_schema` first, or use the migration tool's tracking |
