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

- Reject `SELECT *` in production code. List columns explicitly.
- No functions on indexed columns in `WHERE`. Use range conditions instead:
  - `WHERE YEAR(col) = 2024` → `WHERE col >= '2024-01-01' AND col < '2025-01-01'`
  - `WHERE UPPER(email) = ?` → store / index `LOWER(email)`, compare with `LOWER(?)`
- No `OFFSET` pagination on large tables. Use cursor-based:
  - `LIMIT 20 OFFSET 10000` → `WHERE id > ? ORDER BY id LIMIT 20`
- N+1 detection: any SQL inside a `for` / `while` loop is a red flag. Batch with `IN` clause or JOIN.
- Convert correlated subqueries to JOINs or window functions where feasible.
- Collapse multiple `COUNT(...)` queries into one: `COUNT(CASE WHEN ... THEN 1 END)`.

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

- **MySQL**: InnoDB default, `utf8mb4` charset, `DATETIME` over `TIMESTAMP` for app columns.
- **PostgreSQL**: `JSONB` over `JSON`; `GIN` index for JSONB; `TIMESTAMPTZ` over `TIMESTAMP`.
- **SQL Server**: `DATETIME2` over `DATETIME`; `NVARCHAR` for Unicode; columnstore for analytics.
- **Oracle**: Sequences for surrogate keys; `VARCHAR2` over `VARCHAR`; bind variables (`:name`) over literals.
