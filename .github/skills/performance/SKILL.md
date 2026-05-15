---
name: performance
description: 'Use when user asks about performance optimization, profiling, latency / throughput / memory tuning, or bottleneck analysis. Triggers on: performance optimization, profile, latency, throughput, memory tuning, find bottleneck, slow response, optimize speed, 效能優化, 跑很慢, 記憶體炸了, 怎麼加速, 找瓶頸, 效能調校, 反應太慢. Applies a measure-first methodology across frontend, Java 8 backend, and database layers. Do NOT use for SQL-only optimization (prefer sql-review skill), bug investigation (prefer debug skill), or general code review without performance focus (prefer code-review skill).'
---

# Performance — Workflow

Practical performance tuning. Database rules live in `instructions/sql-rules.instructions.md`.

Full coding standards live in `instructions/*.instructions.md` (auto-applied when matching files are open). When working via agent chat, these non-negotiable rules still apply:

- **SQL**: no `SELECT *`; no functions on indexed columns in `WHERE`; N+1 = SQL inside a loop; cursor pagination over `OFFSET`
- **Logging**: SLF4J parameterized — never `+` concatenation; minimize logging in hot paths
- **Resources**: `try-with-resources` for all `AutoCloseable` — leaked connections cause pool exhaustion under load
- **Security**: no hardcoded secrets; caching must not store sensitive data

## Phase 1 — Methodology

1. **Measure first** — profile before optimizing. Guessing is the enemy of performance.
2. **Set a budget** — define acceptable latency, memory, payload size.
3. **Target the common case** — optimize hot paths, not rare edge cases.
4. **Compare before / after** — every change verified by benchmark, not vibes.

If the user has not measured yet, **stop and profile first**.

## Phase 2 — Pick the Layer

| Symptom | Likely layer | Tools |
|---|---|---|
| TTFB/FCP/LCP poor | Frontend | Chrome DevTools, Lighthouse |
| API latency, CPU spikes | Backend (Java) | VisualVM, async-profiler, JFR |
| Slow queries, lock contention | Database | `EXPLAIN ANALYZE`, slow query log |
| Memory growth, OOM | Backend heap | JFR, heap dumps (jmap, MAT) |

## Phase 3 — Checklist by Layer

**Frontend (JSP / server-rendered):**
- Extract inline styles/scripts to cacheable static files; compress images; minify CSS/JS
- Reduce JSP includes; paginate data-heavy tables server-side
- Enable gzip/Brotli; set Cache-Control headers; use CDN for static assets

**Backend (Java 8):**
- Match data structure to access pattern; reject O(n²) over growing collections
- Async I/O (`CompletableFuture`); bound concurrency via thread pools
- Cache hot reads (TTL/LRU); distributed cache for multi-instance; stampede protection
- Connection pooling (DB, HTTP); bulk operations; compress responses >1KB; paginate results

**Database:**
- Indexes on WHERE/JOIN/ORDER BY; no `SELECT *`; no `OFFSET` pagination
- N+1 → batch with `IN` or JOIN; read replicas for scale

## Phase 4 — Verify

- Re-run same benchmark/profile
- Document before/after numbers
- Confirm no regression on other paths
- If gain <10%, question whether complexity cost is worth it

## Handoffs

- → `sql-review` skill — for deep SQL / index analysis
- → `debug` skill — if the perf problem is actually a bug
- → `refactor` skill — if optimization requires structural change
