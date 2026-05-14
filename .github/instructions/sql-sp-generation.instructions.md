---
description: 'MySQL stored procedure and schema generation conventions. General SQL rules live in sql-rules.instructions.md.'
applyTo: '**/*.sql'
---

# MySQL Stored Procedure & Schema Conventions

Conventions specific to MySQL DDL and stored procedures. For general SQL rules (injection prevention, performance pitfalls), see `instructions/sql-rules.instructions.md`.

## Schema Generation

- Storage engine: InnoDB
- Table & column names: singular, snake_case (e.g., `customer_order`, `created_at`)
- Charset / collation for text: `CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
- Required columns on every table:
  - `id` — PK, AUTO_INCREMENT, UNSIGNED
  - `created_at` — `DATETIME DEFAULT CURRENT_TIMESTAMP`
  - `updated_at` — `DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`
- Use `UNSIGNED` on columns that cannot be negative

## Schema Design

- Foreign key constraints named `fk_<child>_<parent_col>` (e.g., `fk_order_customer_id`)
- Always reference the parent's PK; index every FK column
- Choose `ON DELETE` per relationship:
  - `CASCADE` — child has no meaning without parent (e.g., `order_item` → `order`)
  - `RESTRICT` / `NO ACTION` — parent must be protected (e.g., `order` → `customer`)
  - `SET NULL` — relationship is optional
- Avoid `ON DELETE CASCADE` as a blanket default

## Stored Procedure Naming

- Procedure name prefix: `sp_` (e.g., `sp_get_customer_orders`)
- Plural noun for procedures returning multiple records; singular for single record
- snake_case throughout

## Parameters

- Explicit `IN` / `OUT` / `INOUT` mode
- Name prefix: `p_` (e.g., `p_customer_id`)
- Order: `IN` first, then `OUT`, then `INOUT`
- Default values for optional parameters where supported
- Document each parameter in the header comment block

## Procedure Structure

- Header comment block: description, parameters, author, date
- Local variables: `DECLARE` with `v_` prefix (e.g., `v_total`)
- Error handling: `DECLARE EXIT HANDLER FOR SQLEXCEPTION ...`
- Body wrapped in `BEGIN ... END`
- Custom errors via `SIGNAL SQLSTATE`
- Temporary tables: `tmp_` prefix
- Use `SQL SECURITY INVOKER` or `DEFINER` deliberately, not by default

## Transactions in Stored Procedures

- Explicit `START TRANSACTION` / `COMMIT` / `ROLLBACK`
- Set isolation level when needed: `SET TRANSACTION ISOLATION LEVEL ...`
- Avoid long-running transactions
- Use `SELECT ... FOR UPDATE` only when locking is required for the update
- For bulk work, batch with `LIMIT` to bound transaction size
