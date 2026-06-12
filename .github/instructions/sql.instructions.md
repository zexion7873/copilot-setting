---
description: 'SQL rules — injection prevention, performance, JDBC resources, and MySQL stored procedure conventions.'
applyTo: '**/*.java, **/*.sql, **/*.xml'
---

# SQL Conventions

Non-negotiable rules for all SQL — raw JDBC, HQL, native queries. Hibernate query patterns: `instructions/spring-hibernate.instructions.md`.

## Security

- **JDBC**: all user input via `PreparedStatement` with `?` — zero tolerance for string concatenation
- **HQL / Criteria**: use named parameters (`:paramName`) only — never concatenate into query strings
- Sanitize `LIKE` wildcards before binding
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

## MySQL Stored Procedures

- Naming: `sp_<action>_<entity>`, snake_case
- Parameters: explicit `IN`/`OUT`/`INOUT`, `p_` prefix, `IN` params first
- Body: `DECLARE EXIT HANDLER FOR SQLEXCEPTION` required; variables `v_` prefix
- Tables: InnoDB, `utf8mb4`, `created_at` / `updated_at` timestamps mandatory
- FK: `fk_<child>_<parent_col>`; `RESTRICT` default, `CASCADE` only for dependent children
- Index: `idx_<table>_<columns>`

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
