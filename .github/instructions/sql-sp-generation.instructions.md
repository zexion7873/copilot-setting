---
description: 'Guidelines for generating MySQL SQL statements and stored procedures'
applyTo: '**/*.sql'
---

# SQL Development (MySQL)

## Database Schema Generation
- Use InnoDB as the default storage engine
- All table names should be in singular form and use snake_case (e.g., `customer_order`)
- All column names should be in singular form and use snake_case
- All tables should have a primary key column named `id` with AUTO_INCREMENT
- All tables should have a column named `created_at` of type `DATETIME DEFAULT CURRENT_TIMESTAMP`
- All tables should have a column named `updated_at` of type `DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP`
- Use `UNSIGNED` for columns that should never be negative (e.g., `id`, `quantity`)
- Specify `CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci` for tables containing text data

## Database Schema Design
- All tables should have a primary key constraint
- All foreign key constraints should have a descriptive name (e.g., `fk_order_customer_id`)
- All foreign key constraints should reference the primary key of the parent table
- Choose `ON DELETE` behavior carefully per relationship:
  - `CASCADE` for child records that have no meaning without the parent (e.g., order_item → order)
  - `RESTRICT` or `NO ACTION` for records that should be protected (e.g., order → customer)
  - `SET NULL` when the relationship is optional
- Avoid `ON DELETE CASCADE` as a blanket default — evaluate each relationship individually
- Add indexes on foreign key columns for JOIN performance

## SQL Coding Style
- Use uppercase for SQL keywords (SELECT, FROM, WHERE, INSERT, UPDATE, DELETE)
- Use consistent indentation for nested queries and conditions
- Include comments to explain complex logic
- Break long queries into multiple lines for readability
- Organize clauses consistently (SELECT, FROM, JOIN, WHERE, GROUP BY, HAVING, ORDER BY)
- Use backticks only when column/table names conflict with MySQL reserved words

## SQL Query Structure
- Use explicit column names in SELECT statements instead of SELECT *
- Qualify column names with table name or alias when using multiple tables
- Limit the use of subqueries when JOINs can be used instead
- Include LIMIT clauses to restrict result sets
- Use appropriate indexing for frequently queried columns
- Avoid using functions on indexed columns in WHERE clauses (prevents index usage)
- Use `EXISTS` instead of `IN` for correlated subqueries when appropriate

## Stored Procedure Naming Conventions
- Prefix stored procedure names with `sp_` (e.g., `sp_get_customer_orders`)
- Use snake_case for stored procedure names
- Use descriptive names that indicate purpose
- Include plural noun when returning multiple records (e.g., `sp_get_products`)
- Include singular noun when returning single record (e.g., `sp_get_product`)

## Parameter Handling
- Use `IN`, `OUT`, `INOUT` parameter modes explicitly
- Use snake_case prefixed with `p_` for parameter names (e.g., `p_customer_id`)
- Provide default values for optional parameters where supported
- Validate parameter values before use with IF checks
- Document parameters with comments in the header block
- Arrange parameters consistently (IN first, then OUT, then INOUT)

## Stored Procedure Structure
- Include header comment block with description, parameters, author, and date
- Use DECLARE for local variables with `v_` prefix (e.g., `v_total`)
- Use DECLARE ... HANDLER for error handling (e.g., `DECLARE EXIT HANDLER FOR SQLEXCEPTION`)
- Use BEGIN ... END blocks for procedure body
- Use SIGNAL SQLSTATE for raising custom errors
- Prefix temporary tables with `tmp_`

## SQL Security Best Practices
- Parameterize all queries to prevent SQL injection
- Use prepared statements (`PREPARE`, `EXECUTE`, `DEALLOCATE PREPARE`) when dynamic SQL is necessary
- Avoid embedding credentials in SQL scripts
- Implement proper error handling without exposing system details
- Minimize the use of dynamic SQL within stored procedures
- Use `SQL SECURITY INVOKER` or `DEFINER` appropriately

## Transaction Management
- Explicitly use `START TRANSACTION`, `COMMIT`, and `ROLLBACK`
- Set appropriate transaction isolation levels (`SET TRANSACTION ISOLATION LEVEL ...`)
- Avoid long-running transactions that lock rows/tables
- Use batch processing with LIMIT for large data operations
- Use `SELECT ... FOR UPDATE` when locking rows for modification
