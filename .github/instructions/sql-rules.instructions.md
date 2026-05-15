---
description: 'SQL hard rules covering injection prevention, performance pitfalls, and JDBC resource handling.'
applyTo: '**/*.java, **/*.sql, **/*.xml, **/*.jsp'
---

# SQL Rules

Non-negotiable rules for any SQL in this project. MySQL stored procedure conventions live in `instructions/sql-sp-generation.instructions.md`.

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
