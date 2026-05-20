---
name: performance
description: 'Use when user reports slow response, high memory, or needs bottleneck analysis and optimization. Triggers on: performance, slow, latency, throughput, memory, bottleneck, optimize speed, 效能, 跑很慢, 記憶體, 怎麼加速, 找瓶頸, 效能調校. Applies measure-first methodology. Do NOT use for SQL-only review (prefer sql-review), bug investigation (prefer debug), or general code review (prefer code-review).'
---

# Performance — Workflow

Measure-first performance tuning. SQL performance rules: `instructions/sql.instructions.md`.

**Canonical rules — open the instruction files for the layers you touch** (agent mode can read them directly):

- `instructions/java.instructions.md` — Java 8 language boundary
- `instructions/spring-hibernate.instructions.md` — Spring 3.2 + Hibernate 4.2
- `instructions/sql.instructions.md` — SQL injection, indexing, JDBC resources
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

If you cannot open files, Key rules (fallback for agent chat):

- **Java 8**: no `var`, no `List.of()`, no records — checked exceptions must be handled or declared
- **Spring 3.2**: XML config + `<tx:advice>` only, no `@Transactional`, no Spring Boot
- **Hibernate 4.2**: `getCurrentSession()` only, `hbm.xml` mappings, no JPA annotations
- **SQL (JDBC)**: `PreparedStatement` with `?` — zero string concatenation
- **SQL (HQL)**: named parameters (`:param`) — never concatenate into query strings

## Phase 1 — Measure First

1. **Profile before optimizing** — guessing is the enemy of performance
2. **Set a budget** — define acceptable latency / memory / payload size
3. **Target hot paths** — optimize common case, not rare edges

If the user has not measured yet, **stop and ask them to profile first**.

## Phase 2 — Identify Layer

| Symptom | Layer | Tools |
|---|---|---|
| Slow page load (TTFB/FCP/LCP) | Frontend / JSP | Chrome DevTools, Lighthouse |
| API latency, CPU spikes | Backend (Java) | VisualVM, async-profiler, JFR |
| Slow queries, lock contention | Database | `EXPLAIN ANALYZE`, slow query log |
| Memory growth, OOM | Heap | JFR, heap dumps (jmap, MAT) |

## Phase 3 — Apply Fixes

**Backend**: match data structure to access pattern; reject O(n²); connection pooling; cache hot reads (TTL/LRU); bulk operations; compress responses >1KB

**Database**: indexes on WHERE/JOIN/ORDER BY; no `SELECT *`; no `OFFSET`; N+1 → batch; read replicas

**Frontend**: extract inline resources to cacheable files; paginate tables; gzip/Brotli; CDN for static

## Phase 4 — Verify

- Re-run same profile/benchmark
- Document before/after numbers
- If gain <10%, question whether complexity cost is worth it

## Handoffs

- → `sql-review` skill — for deep SQL / index analysis
- → `debug` skill — if the performance problem is actually a bug
- → `refactor` skill — if optimization requires structural change
