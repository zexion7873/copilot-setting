---
description: 'SQL hard rules covering injection prevention, performance pitfalls, and JDBC resource handling.'
applyTo: '**/*.java, **/*.sql, **/*.xml, **/*.jsp'
---

# SQL Rules

Non-negotiable rules for any SQL in this project. MySQL stored procedure conventions live in `instructions/sql-sp-generation.instructions.md`. Hibernate-specific conventions live in `instructions/hibernate.instructions.md` — this file covers raw JDBC paths and the rules that apply to any SQL (including HQL / native queries through Hibernate).

## When to Use Hibernate vs Raw JDBC

| Use case | Choice |
|---|---|
| CRUD on a single entity / aggregate | Hibernate |
| Loading entity with associations | Hibernate (with appropriate fetch strategy) |
| Complex aggregation / reporting query | Raw JDBC `PreparedStatement` |
| Batch insert / update / delete of 1000+ rows | Hibernate `StatelessSession` OR raw JDBC batch |
| Bulk `DELETE` / `UPDATE` by criteria | Raw JDBC OR HQL `DELETE` (note: bypasses Hibernate cache) |
| DDL / schema migration | Raw JDBC; never run from application code in production |
| One-off ad hoc queries | Raw JDBC |

## Security

- All user input MUST be parameterized — `PreparedStatement` with `?` placeholders. No string concatenation.
- Sanitize `LIKE` wildcards before binding when pattern includes user input.
- No `SELECT *` on tables with sensitive columns. List only what the caller needs.
- Never log SQL strings containing credentials or PII.

## Performance

- No `SELECT *` — list columns explicitly.
- No functions on indexed columns in `WHERE` — use range conditions instead.
- No `OFFSET` pagination on large tables — use cursor-based (`WHERE id > ? ORDER BY id LIMIT N`).
- N+1 detection: SQL inside a loop is a red flag. Batch with `IN` or JOIN.
- Prefer `EXISTS` over `IN` for existence checks on large subqueries.
- Batch INSERT/UPDATE/DELETE (500-1000 rows) — never row-by-row.

## Code Quality

- `WHERE` clause MUST exist on every `UPDATE` and `DELETE`.
- Use `IF EXISTS` / `IF NOT EXISTS` guards on DDL.
- Table aliases meaningful (`u` for users, `o` for orders — not `a`, `b`).

## Java JDBC Resource Handling

- `try-with-resources` for `Connection`, `PreparedStatement`, `ResultSet`.
- Transactions must commit OR rollback on every code path.
- Never leak connections in error paths.

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `"SELECT * FROM users WHERE name = '" + name + "'"` | SQL injection — attacker controls the query | `PreparedStatement` with `?`: `"WHERE name = ?"` + `setString(1, name)` |
| `SELECT * FROM orders` | Fetches unnecessary columns; breaks when schema changes | List columns explicitly: `SELECT id, customer_id, total FROM orders` |
| `WHERE YEAR(created_at) = 2024` | Function on indexed column prevents index use; full table scan | Range condition: `WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01'` |
| `SELECT ... LIMIT 10 OFFSET 10000` on large table | Scans and discards 10,000 rows every query | Cursor pagination: `WHERE id > ? ORDER BY id LIMIT 10` |
| `for (id : ids) { stmt.executeQuery("...id=" + id) }` | N+1 queries — one round-trip per iteration | Batch: `WHERE id IN (?, ?, ...)` or use JOIN |
| `DELETE FROM orders` (no `WHERE`) | Deletes entire table contents | Always include `WHERE` clause on `UPDATE` / `DELETE` |
| `Connection` not in `try-with-resources` | Connection leak on exception; pool exhaustion under load | `try (Connection c = ds.getConnection()) { ... }` |
