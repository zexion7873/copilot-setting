---
name: performance
description: 'Use when user reports slow response, high memory, or needs bottleneck analysis and optimization. Triggers on: performance, slow, latency, throughput, memory, bottleneck, optimize speed, 效能, 跑很慢, 記憶體, 怎麼加速, 找瓶頸, 效能調校. Applies measure-first methodology. Do NOT use for SQL-only review (prefer sql-review), bug investigation (prefer debug), or general code review (prefer code-review).'
---

# Performance — Workflow

Measure-first performance tuning. SQL rules: `instructions/sql.instructions.md`.

Full coding rules in `instructions/*.instructions.md`. Key rules:

- **SQL**: no `SELECT *`; no functions on indexed columns; cursor pagination; N+1 = SQL in loop
- **Resources**: `try-with-resources` — leaked connections cause pool exhaustion under load
- **Security**: caching must not store sensitive data

## Methodology

1. **Measure first** — profile before optimizing. No measurement = no optimization.
2. **Set a budget** — define acceptable latency / memory / payload size.
3. **Target hot paths** — common case, not rare edges.
4. **Compare before / after** — every change verified by benchmark.

If the user has not measured yet, **stop and ask them to profile first**.

## Layer → Symptom Map

| Symptom | Layer | Tools |
|---|---|---|
| Slow page load | Frontend / JSP | Chrome DevTools, Lighthouse |
| API latency, CPU spikes | Backend (Java) | VisualVM, async-profiler, JFR |
| Slow queries, lock contention | Database | `EXPLAIN ANALYZE`, slow query log |
| Memory growth, OOM | Heap | JFR, heap dumps (jmap, MAT) |

## Common Fixes

- **Backend**: match data structure to access pattern; connection pooling; cache hot reads (TTL/LRU); bulk operations; compress >1KB
- **Database**: indexes on WHERE/JOIN/ORDER BY; no `SELECT *`; no `OFFSET`; N+1 → batch
- **Frontend**: cacheable static files; paginate tables; gzip/Brotli; CDN

## Handoffs

- → `sql-review` skill — deep SQL / index analysis
- → `debug` skill — performance problem is actually a bug
- → `refactor` skill — optimization requires structural change
