---
description: 'SQL rules — injection prevention, performance, JDBC resources, and MySQL stored procedure conventions.'
applyTo: '**/*.java, **/*.sql, **/*.xml'
---

# SQL Conventions

Non-negotiable rules for all SQL — raw JDBC, HQL, native queries. Hibernate query patterns: `instructions/spring-hibernate.instructions.md`.

## Security

- All user input via `PreparedStatement` with `?` — zero tolerance for concatenation
- Sanitize `LIKE` wildcards before binding
- No `SELECT *` on tables with sensitive columns
- Never log SQL containing credentials or PII

## Performance

- No `SELECT *` — list columns explicitly
- No functions on indexed columns in `WHERE` — use range conditions
- No `OFFSET` pagination on large tables — cursor: `WHERE id > ? ORDER BY id LIMIT N`
- N+1 = SQL inside a loop — batch with `IN` or JOIN
- `EXISTS` over `IN` for large subqueries
- Batch INSERT/UPDATE/DELETE (500–1000 rows); never row-by-row

## JDBC Resources

- `try-with-resources` for `Connection`, `PreparedStatement`, `ResultSet`
- `WHERE` clause mandatory on every `UPDATE` and `DELETE`
- Transactions: commit or rollback on every code path

## MySQL Stored Procedures

- Naming: `sp_<action>_<entity>`, snake_case
- Parameters: explicit `IN`/`OUT`/`INOUT`, `p_` prefix, `IN` params first
- Body: `DECLARE EXIT HANDLER FOR SQLEXCEPTION` required; variables `v_` prefix
- Tables: InnoDB, `utf8mb4`, `created_at` / `updated_at` timestamps mandatory
- FK: `fk_<child>_<parent_col>`; `RESTRICT` default, `CASCADE` only for dependent children

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
