---
name: sql-review
description: 'Structured SQL review and optimization workflow for database code quality and performance. Use when user asks to review SQL, optimize queries, analyze execution plans, or mentions "/sql-review". Walks through: query inventory, security audit (injection prevention), performance analysis (execution plans, index strategy), code quality review, anti-pattern detection, and optimization recommendations. Designed for @sql-expert agent but usable by any agent reviewing SQL.'
license: MIT
allowed-tools: ['search', 'read/problems', 'execute/runInTerminal']
---

# SQL Review — Executable Workflow

## Overview

A unified SQL review and optimization process that combines security auditing, performance analysis, and code quality review into one systematic pass. This skill defines HOW to review SQL, not WHAT the rules are (those live in the agent prompt and instructions).

## When to Use

- User asks to review SQL queries, stored procedures, or migrations
- User asks to optimize a slow query or analyze an execution plan
- User mentions `/sql-review` or "check my SQL"
- Pre-merge review of database-touching code
- Investigating a performance regression in a Java JDBC layer

---

## Phase 1 — Inventory the SQL

Before reviewing anything, map what you're working with.

### 1.1 Identify SQL in Scope

Search for SQL across the codebase:

```bash
# Find inline SQL strings in Java files
grep -rn "SELECT\|INSERT\|UPDATE\|DELETE\|CREATE\|ALTER\|DROP" --include="*.java" src/

# Find SQL files (migrations, stored procedures)
find . -name "*.sql" -not -path "*/target/*"

# Find SQL in XML config (MyBatis, etc.)
grep -rn "SELECT\|INSERT\|UPDATE\|DELETE" --include="*.xml" src/
```

### 1.2 Build the SQL Inventory Table

For each query found, record:

| # | Location (File#Method) | Type | Parameterized? | Notes |
|---|------------------------|------|----------------|-------|
| 1 | `UserDao.java#findById` | SELECT | Yes (`?`) | |
| 2 | `OrderDao.java#search` | SELECT | No (concat) | CRITICAL |
| 3 | `migrations/V3__add_index.sql` | DDL | N/A | |

**Classify each query:**
- `SELECT` / `INSERT` / `UPDATE` / `DELETE` / `DDL` / `DML`
- Parameterization status: `PreparedStatement ?` vs `String concat` vs `N/A`
- Calling context: which Java method executes this query?

---

## Phase 2 — Security Review

Security is the first priority. A slow query is a problem; an injectable query is a crisis.

### 2.1 SQL Injection Detection

Search for string concatenation in SQL construction:

```bash
# Java string concatenation patterns
grep -rn '"SELECT.*".*+\|"WHERE.*".*+\|"INSERT.*".*+' --include="*.java" src/
grep -rn 'String\.format.*SELECT\|String\.format.*WHERE' --include="*.java" src/
grep -rn '\.append.*SELECT\|\.append.*WHERE\|\.append.*AND' --include="*.java" src/
```

**Vulnerable pattern (CRITICAL):**

```java
// NEVER do this
String sql = "SELECT * FROM users WHERE name = '" + userName + "'";
Statement stmt = conn.createStatement();
ResultSet rs = stmt.executeQuery(sql);
```

**Secure pattern:**

```java
// Always use PreparedStatement with ? placeholders
String sql = "SELECT id, name, email FROM users WHERE name = ?";
PreparedStatement ps = conn.prepareStatement(sql);
ps.setString(1, userName);
ResultSet rs = ps.executeQuery();
```

### 2.2 Parameterization Checklist

```
□ All user-supplied values use ? placeholders
□ No String.format() or + concatenation building SQL
□ StringBuilder.append() not used to inject values
□ LIKE patterns sanitize % and _ wildcards
□ IN clauses use parameterized lists, not string-joined values
```

**LIKE sanitization example:**

```java
// Sanitize wildcard characters before binding
String safeTerm = userInput.replace("\\", "\\\\")
                           .replace("%", "\\%")
                           .replace("_", "\\_");
ps.setString(1, "%" + safeTerm + "%");
```

### 2.3 Access Control Review

```
□ Database account uses least-privilege (no DBA/root for app queries)
□ Sensitive columns (passwords, tokens, PII) not returned to caller unnecessarily
□ No sensitive data logged via log.debug() or log.info()
□ SELECT * avoided on tables with sensitive columns
```

---

## Phase 3 — Performance Analysis

Work through performance systematically. Don't guess; measure.

### 3.1 Execution Plan Analysis

Run EXPLAIN on every non-trivial SELECT before optimizing:

```sql
-- MySQL: basic plan
EXPLAIN SELECT u.id, u.name
FROM users u
INNER JOIN orders o ON u.id = o.user_id
WHERE o.status = 'pending';

-- MySQL: actual runtime stats (MySQL 8.0+)
EXPLAIN ANALYZE SELECT u.id, u.name
FROM users u
INNER JOIN orders o ON u.id = o.user_id
WHERE o.status = 'pending';

-- PostgreSQL: full analysis with buffer stats
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT u.id, u.name
FROM users u
INNER JOIN orders o ON u.id = o.user_id
WHERE o.status = 'pending';
```

**What to look for in the output:**

| Signal | Meaning | Action |
|--------|---------|--------|
| `type: ALL` (MySQL) / `Seq Scan` (PG) | Full table scan | Add index on WHERE/JOIN column |
| `Using filesort` | Sort without index | Add index on ORDER BY column |
| `Using temporary` | Temp table created | Rewrite query or add covering index |
| `rows` estimate very high | Optimizer underestimates | Check statistics, consider hints |
| Nested loop on large tables | Inefficient join | Check join column indexes |

### 3.2 Index Strategy Review

**Missing indexes — check these columns first:**

```sql
-- MySQL: find tables with no indexes (besides PK)
SELECT table_name
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name NOT IN (
      SELECT DISTINCT table_name
      FROM information_schema.statistics
      WHERE table_schema = DATABASE()
        AND index_name != 'PRIMARY'
  );
```

**Index design rules:**

```
□ WHERE clause columns have indexes (most selective column first)
□ JOIN columns on the "many" side have indexes
□ ORDER BY columns covered by an index (avoids filesort)
□ Composite index column order matches query filter order
□ Write-heavy tables not over-indexed (each index slows INSERT/UPDATE)
□ Covering indexes used for high-frequency queries
```

**Composite index example:**

```sql
-- Query: WHERE status = 'active' AND created_at > '2024-01-01' ORDER BY created_at
-- Put the equality filter first, range filter second
CREATE INDEX idx_orders_status_created ON orders(status, created_at);

-- Covering index: includes all columns the query needs (avoids table lookup)
CREATE INDEX idx_orders_covering ON orders(status, created_at, id, total_amount);
```

### 3.3 Query Pattern Issues

**SELECT * — always replace:**

```java
// Before
String sql = "SELECT * FROM products WHERE category_id = ?";

// After — list only what the caller actually uses
String sql = "SELECT id, name, price, stock_quantity FROM products WHERE category_id = ?";
```

**Function on indexed column — prevents index use:**

```sql
-- Before: YEAR() forces full scan
SELECT * FROM orders WHERE YEAR(created_at) = 2024;

-- After: range condition uses index
SELECT id, customer_id, total_amount
FROM orders
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';
```

**N+1 in Java JDBC — the most common performance killer:**

```java
// Before: N+1 — one query per user
List<User> users = findAllUsers();
for (User user : users) {
    List<Order> orders = findOrdersByUserId(user.getId()); // N queries
}

// After: single JOIN query
String sql = "SELECT u.id, u.name, o.id AS order_id, o.total_amount " +
             "FROM users u " +
             "LEFT JOIN orders o ON u.id = o.user_id " +
             "WHERE u.status = ?";
```

**OFFSET pagination on large tables:**

```java
// Before: OFFSET 50000 scans 50,020 rows to return 20
String sql = "SELECT id, name FROM products ORDER BY id LIMIT ? OFFSET ?";

// After: cursor-based pagination scans only 20 rows
String sql = "SELECT id, name FROM products WHERE id > ? ORDER BY id LIMIT ?";
// Pass the last seen ID as the cursor
```

### 3.4 Join Optimization

```
□ INNER JOIN used when NULL rows on either side are not needed
□ LEFT JOIN used intentionally (not by habit)
□ All JOIN conditions present — no accidental cartesian products
□ DISTINCT not masking a broken JOIN (fix the JOIN instead)
□ Correlated subqueries converted to JOINs or window functions
```

**Correlated subquery to JOIN:**

```sql
-- Before: correlated subquery runs once per row
SELECT p.name, p.price
FROM products p
WHERE p.price > (
    SELECT AVG(price) FROM products p2 WHERE p2.category_id = p.category_id
);

-- After: window function runs once
SELECT name, price
FROM (
    SELECT name, price,
           AVG(price) OVER (PARTITION BY category_id) AS avg_category_price
    FROM products
) sub
WHERE price > avg_category_price;
```

---

## Phase 4 — Code Quality Review

### 4.1 Naming and Formatting

```
□ Table aliases are meaningful (not a, b, c — use u for users, o for orders)
□ SQL keywords consistently cased (prefer uppercase: SELECT, FROM, WHERE)
□ Indentation consistent — each clause on its own line
□ Column list formatted one-per-line for queries with 4+ columns
□ Complex business logic has a comment explaining WHY, not WHAT
```

**Formatting example:**

```sql
-- Before: unreadable
select u.id,u.name,o.total from users u left join orders o on u.id=o.user_id where u.status='active';

-- After: readable
SELECT u.id,
       u.name,
       o.total
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.status = 'active';
```

### 4.2 Schema and Data Type Review

```
□ Primary keys use INT or BIGINT (not VARCHAR)
□ Timestamps use DATETIME or TIMESTAMP (not VARCHAR)
□ Monetary values use DECIMAL(precision, scale) (not FLOAT/DOUBLE)
□ NOT NULL constraints on columns that should never be null
□ DEFAULT values set where appropriate
□ Foreign key constraints defined (or documented reason for omission)
□ CHECK constraints used for enum-like columns where supported
```

### 4.3 Transaction and Resource Handling (Java JDBC)

```java
// Correct pattern: try-with-resources + explicit transaction
Connection conn = dataSource.getConnection();
try {
    conn.setAutoCommit(false);
    // ... execute queries
    conn.commit();
} catch (SQLException e) {
    conn.rollback();
    throw e;
} finally {
    conn.close();
}
```

```
□ Connections closed in finally block or try-with-resources
□ ResultSet and PreparedStatement closed after use
□ Transactions committed or rolled back on all code paths
□ Batch size bounded (500-1000 rows) for bulk operations
```

---

## Phase 5 — Anti-Pattern Detection

Run these searches against the codebase:

| Anti-Pattern | Search Pattern | Fix |
|---|---|---|
| SQL injection | `"SELECT.*" +` or `"WHERE.*" +` | Use `PreparedStatement` with `?` |
| SELECT * | `SELECT \*` or `select \*` | List specific columns |
| N+1 queries | SQL execution inside a loop | Batch with `IN` or `JOIN` |
| Missing WHERE on UPDATE/DELETE | `UPDATE\s+\w+\s+SET` without `WHERE` | Add `WHERE` clause |
| DISTINCT masking bad JOIN | `SELECT DISTINCT` with multiple JOINs | Fix JOIN conditions |
| Function on indexed column | `WHERE YEAR(`, `WHERE UPPER(`, `WHERE DATE(` | Use range conditions |
| OFFSET pagination | `LIMIT \d+ OFFSET \d+` | Cursor-based pagination |
| Implicit type conversion | String compared to INT column | Match types explicitly |
| Correlated subquery | `WHERE x = (SELECT ... WHERE outer.col)` | Rewrite as JOIN or window function |
| Unbounded result set | SELECT without LIMIT in app code | Add LIMIT or paginate |

---

## Phase 6 — Optimization Recommendations

For each finding, produce a structured recommendation:

```
[Issue]        Description of the problem
[Impact]       High / Medium / Low — estimated performance or security impact
[Current]      Current query or Java code snippet
[Optimized]    Improved version
[Why]          Explanation of why this is better
[Index]        Suggested index DDL, if applicable
[Verification] How to confirm the improvement (EXPLAIN output, benchmark)
```

**Example:**

```
[Issue]        Full table scan on orders.status column
[Impact]       High — orders table has 2M rows; query takes 4s
[Current]      SELECT id, total FROM orders WHERE status = 'pending'
[Optimized]    Same query — add index below
[Why]          Without an index, MySQL scans all 2M rows. With the index,
               it reads only the ~5k pending rows.
[Index]        CREATE INDEX idx_orders_status ON orders(status);
[Verification] Run EXPLAIN before and after. "type" should change from
               ALL to ref, and "rows" should drop from 2M to ~5k.
```

---

## Summary Report

Output this at the end of every review:

```
## SQL Review Summary

| Category                          | Issues Found |
|-----------------------------------|-------------|
| 🔴 Security (injection risk)      | N           |
| 🟠 Performance (critical)         | N           |
| 🟡 Performance (improvement)      | N           |
| 🔵 Code Quality                   | N           |

### Top 3 Priority Actions
1. [Most urgent — usually security]
2. [Second priority]
3. [Third priority]

### Scores
- Security:        [1-10]
- Performance:     [1-10]
- Maintainability: [1-10]
```

---

## SQL Review Anti-Patterns

Avoid these mistakes during the review itself:

| Anti-Pattern | Why It Fails | Do This Instead |
|---|---|---|
| Reviewing SQL without execution plans | Guessing at performance | Always run EXPLAIN first |
| Optimizing without measuring | May make things worse | Benchmark before and after |
| Adding indexes without checking write impact | Slows INSERT/UPDATE | Consider write frequency |
| Fixing SQL without checking calling Java code | May need N+1 fix in Java layer | Trace from DAO to caller |
| Reporting every style issue as critical | Noise drowns real problems | Use severity levels consistently |
| Skipping the security phase | Injection risk goes undetected | Always audit parameterization first |
