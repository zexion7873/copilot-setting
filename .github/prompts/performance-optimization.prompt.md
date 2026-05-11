---
agent: 'agent'
description: 'Performance optimization checklist covering profiling, frontend, backend (Java 8), and database. DB rules live in instructions/sql-rules.instructions.md.'
---

# Performance Optimization

Practical performance tuning checklist. Database rules live in `instructions/sql-rules.instructions.md`. This prompt covers methodology, frontend, backend (Java 8), and profiling.

## Methodology

1. **Measure first** — profile before optimizing. Guessing is the enemy of performance.
2. **Set a budget** — define acceptable latency, memory, payload size; enforce in CI.
3. **Target the common case** — optimize hot paths, not rare edge cases.
4. **Compare before / after** — every change verified by benchmark, not vibes.
5. **Avoid premature optimization** — write clear code first; optimize where measurement says.

## Frontend (browser)

### Rendering
- Batch DOM mutations; build off-DOM fragments before insertion
- Stable keys on list items; never array index for dynamic lists
- CSS animations over JS (GPU-accelerated, off the main thread)
- Defer non-critical work via `requestIdleCallback`

### Assets
- Modern image formats (WebP, AVIF); compress aggressively
- Subset fonts; `font-display: swap`
- Minify + tree-shake JS / CSS; long-cache static assets with cache busting

### Network
- HTTP/2 or HTTP/3 for multiplexing
- `<link rel="preload">` for critical resources; `defer` / `async` for non-critical JS
- CDN for static assets; client-side cache (Service Worker, IndexedDB)
- Lazy-load images (`loading="lazy"`) and route-level code splits

### JavaScript hot paths
- Offload heavy compute to Web Workers
- Debounce / throttle scroll, resize, input handlers
- `Map` / `Set` for O(1) lookups; TypedArrays for numeric data
- Avoid deep clones inside render paths

## Backend (Java 8)

### Algorithm & data
- Match data structure to access pattern (`HashMap` for lookup, `ArrayDeque` for queue)
- Reject O(n²) over collections that can grow
- Stream large data sets via `Stream` / iterators; don't load into memory

### Concurrency
- Async I/O (`CompletableFuture`); never block in request-serving threads
- Bound concurrency via thread pools (`Executors.newFixedThreadPool`) — prevent exhaustion
- `ConcurrentHashMap` over synchronized maps; `AtomicLong` over locks for counters
- Watch hidden contention: `synchronized` on hot paths, contended CAS loops

### Caching
- Cache hot reads; pick eviction per volatility (TTL / LRU)
- Distributed cache (Redis / Memcached) for multi-instance setups
- Cache stampede protection: request coalescing, jittered TTL
- Don't cache freshness-sensitive data (auth, balances)

### I/O & network
- Connection pooling (DB, HTTP); never open per-request
- Bulk operations: batch INSERT, bulk HTTP requests
- Compress responses (gzip, Brotli) for >1KB payloads
- Pagination / cursors for large result sets — never return unbounded lists

### Logging
- Minimize logging in hot paths; DEBUG level by default
- Parameterized logging (`log.info("user={}", id)`) — never `+` concatenation
- Structured (JSON) logs for production aggregation

## Database

Apply rules from `instructions/sql-rules.instructions.md`. Key reminders:

- Indexes on WHERE / JOIN / ORDER BY; composite order matches predicate order
- No `SELECT *`, no functions on indexed columns, no `OFFSET` pagination on large tables
- Detect N+1 (SQL inside loops); batch with `IN` or JOIN
- Read replicas for scale; bounded transaction lifetime

## Profiling Tools

- Frontend: Chrome DevTools (Performance tab), Lighthouse, WebPageTest
- Java: VisualVM, JProfiler, async-profiler, JFR (Java Flight Recorder)
- DB: `EXPLAIN ANALYZE` (MySQL 8+), `pg_stat_statements` (PostgreSQL), slow query log
- Load testing: k6, Gatling, JMeter, Locust

## Quick Checklist

- [ ] Profiled before optimizing? (no guessing)
- [ ] Budget defined and enforced in CI?
- [ ] No N+1 queries (DB calls outside loops)?
- [ ] Hot paths cached appropriately?
- [ ] Async I/O for blocking calls?
- [ ] Large payloads paginated / streamed / compressed?
- [ ] Resources cleaned up (try-with-resources for `AutoCloseable`)?
- [ ] Memory monitored; no unbounded caches or collections?
