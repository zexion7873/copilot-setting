---
description: 'SQL hard rules covering injection prevention, performance pitfalls, indexing, pagination, and code quality. Single source of truth for SQL across all file types that may contain it.'
applyTo: '**/*.java, **/*.sql, **/*.xml, **/*.jsp'
---

# SQL Rules

Hard rules for any SQL written in this project. These are non-negotiable; deviation requires an explicit comment explaining why.

## Security

- All user input MUST be parameterized — `PreparedStatement` with `?` placeholders. No string concatenation, `String.format`, or StringBuilder append for building SQL with user data.
- Sanitize `LIKE` wildcards (`%`, `_`, `\`) before binding when the pattern includes user input.
- Avoid `SELECT *` on tables containing sensitive columns (passwords, tokens, PII). List only what the caller needs.
- Use least-privilege database accounts; the application account is never DBA / root.
- Never log SQL strings containing credentials, tokens, or PII.

## Performance — Query Patterns

- Reject `SELECT *`. List columns explicitly.
- No functions on indexed columns in `WHERE` — use range conditions (`WHERE YEAR(col) = 2024` → `WHERE col >= '2024-01-01' AND col < '2025-01-01'`).
- No `OFFSET` pagination on large tables — use cursor-based (`WHERE id > ? ORDER BY id LIMIT 20`).
- N+1 detection: SQL inside a loop is a red flag. Batch with `IN` or JOIN.
- Prefer JOINs or window functions over correlated subqueries.
- Collapse multiple `COUNT(...)` into one with `CASE WHEN`.

## Performance — Indexes

- Index columns used in WHERE, JOIN, ORDER BY — but watch over-indexing (write cost).
- Composite index column order must match query predicate order; most selective column first.
- Use covering indexes for hot read paths (SQL Server `INCLUDE`, extra columns elsewhere).
- Use partial / filtered indexes for skewed data (`WHERE status IN ('pending', 'processing')`).

## Performance — Joins & Bulk Ops

- Prefer explicit `INNER JOIN` over comma-separated FROM (cartesian risk).
- `DISTINCT` is usually a band-aid for a missing JOIN condition — fix the JOIN.
- Prefer `EXISTS` over `IN` for existence checks on large subqueries.
- Batch INSERT/UPDATE/DELETE — never row-by-row. Bound batch size to 500-1000 rows.
- Migrations: wrap multi-statement work in explicit `BEGIN`/`COMMIT`; chunk large updates.

## Code Quality

- `WHERE` clause MUST exist on every `UPDATE` and `DELETE`. No exceptions.
- Use `IF EXISTS` / `IF NOT EXISTS` guards on DDL statements.
- SQL keywords UPPER; identifiers per project convention (typically snake_case).
- Table aliases meaningful (`u` for users, `o` for orders — not `a`, `b`, `c`).
- Use appropriate data types — no `VARCHAR(255)` as a default for every text column.
- Comment only non-obvious WHERE / JOIN logic; skip the obvious.

## Java JDBC Resource Handling

- Use try-with-resources for `Connection`, `PreparedStatement`, `ResultSet`.
- Transactions must commit OR rollback on every code path.
- Never leak connections in error paths.

## Database-Specific Notes

- **MySQL** (primary): InnoDB default, `utf8mb4` charset, `DATETIME` over `TIMESTAMP` for app columns.
- Other dialects (PostgreSQL, SQL Server, Oracle): apply equivalent type/index conventions for that dialect.
