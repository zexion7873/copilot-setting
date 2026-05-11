---
name: performance
description: 'Use when user asks about performance optimization, profiling, latency / throughput / memory tuning, or 效能優化 / 跑很慢 / 記憶體炸了 / 怎麼加速 / 找瓶頸. Applies a measure-first methodology and a checklist across frontend, Java 8 backend, database (defers to sql-rules), and profiling tools. Do NOT use for SQL-only optimization (prefer sql-review skill), bug investigation (prefer debug skill), or general code review without performance focus (prefer code-review skill).'
---

# Performance — Workflow

Practical performance tuning. Database rules live in `instructions/sql-rules.instructions.md` — defer there for SQL specifics. This skill covers methodology and the cross-stack checklist.

## Phase 1 — Methodology (apply before any change)

1. **Measure first** — profile before optimizing. Guessing is the enemy of performance.
2. **Set a budget** — define acceptable latency, memory, payload size; enforce in CI.
3. **Target the common case** — optimize hot paths, not rare edge cases.
4. **Compare before / after** — every change verified by benchmark, not vibes.
5. **Avoid premature optimization** — write clear code first; optimize where measurement says.

If the user has not measured yet, **stop and profile first**. Suggesting a "fix" without numbers is malpractice.

## Phase 2 — Pick the Layer

Identify which layer is slow before opening checklists:

| Symptom | Likely layer | Tools |
|---|---|---|
| TTFB high, FCP slow, LCP poor | Frontend | Chrome DevTools (Performance), Lighthouse, WebPageTest |
| API latency high, CPU spikes | Backend (Java) | VisualVM, JProfiler, async-profiler, JFR |
| Slow queries, lock contention | Database | `EXPLAIN ANALYZE`, slow query log, `pg_stat_statements` |
| Memory growth, OOM | Backend / heap | JFR, heap dumps (`jmap`, MAT) |
| Network bound | Cross-layer | k6, Gatling, JMeter, browser network panel |

## Phase 3 — Apply the Checklist

### Frontend (browser)

**Rendering**
- Batch DOM mutations; build off-DOM fragments before insertion
- Stable keys on list items; never array index for dynamic lists
- CSS animations over JS (GPU-accelerated, off the main thread)
- Defer non-critical work via `requestIdleCallback`

**Assets**
- Modern image formats (WebP, AVIF); compress aggressively
- Subset fonts; `font-display: swap`
- Minify + tree-shake JS / CSS; long-cache static assets with cache busting

**Network**
- HTTP/2 or HTTP/3 for multiplexing
- `<link rel="preload">` for critical resources; `defer` / `async` for non-critical JS
- CDN for static assets; client-side cache (Service Worker, IndexedDB)
- Lazy-load images (`loading="lazy"`) and route-level code splits

**JavaScript hot paths**
- Offload heavy compute to Web Workers
- Debounce / throttle scroll, resize, input handlers
- `Map` / `Set` for O(1) lookups; TypedArrays for numeric data
- Avoid deep clones inside render paths

### Backend (Java 8)

**Algorithm & data**
- Match data structure to access pattern (`HashMap` for lookup, `ArrayDeque` for queue)
- Reject O(n²) over collections that can grow
- Stream large data sets via `Stream` / iterators; don't load into memory

**Concurrency**
- Async I/O (`CompletableFuture`); never block in request-serving threads
- Bound concurrency via thread pools (`Executors.newFixedThreadPool`) — prevent exhaustion
- `ConcurrentHashMap` over synchronized maps; `AtomicLong` over locks for counters
- Watch hidden contention: `synchronized` on hot paths, contended CAS loops

**Caching**
- Cache hot reads; pick eviction per volatility (TTL / LRU)
- Distributed cache (Redis / Memcached) for multi-instance setups
- Cache stampede protection: request coalescing, jittered TTL
- Don't cache freshness-sensitive data (auth, balances)

**I/O & network**
- Connection pooling (DB, HTTP); never open per-request
- Bulk operations: batch INSERT, bulk HTTP requests
- Compress responses (gzip, Brotli) for >1KB payloads
- Pagination / cursors for large result sets — never return unbounded lists

**Logging**
- Minimize logging in hot paths; DEBUG level by default
- Parameterized logging (`log.info("user={}", id)`) — never `+` concatenation
- Structured (JSON) logs for production aggregation

### Database

Apply rules from `instructions/sql-rules.instructions.md`. Key reminders:

- Indexes on WHERE / JOIN / ORDER BY; composite order matches predicate order
- No `SELECT *`, no functions on indexed columns, no `OFFSET` pagination on large tables
- Detect N+1 (SQL inside loops); batch with `IN` or JOIN
- Read replicas for scale; bounded transaction lifetime

For deeper SQL audits, hand off to `sql-review` skill.

## Phase 4 — Verify

Every change must close the loop:

- [ ] Re-run the same benchmark / profile
- [ ] Document before / after numbers
- [ ] Confirm no regression on other paths
- [ ] If gain is <10%, ask whether the complexity cost is worth it

## Quick Checklist

- [ ] Profiled before optimizing? (no guessing)
- [ ] Budget defined and enforced in CI?
- [ ] No N+1 queries (DB calls outside loops)?
- [ ] Hot paths cached appropriately?
- [ ] Async I/O for blocking calls?
- [ ] Large payloads paginated / streamed / compressed?
- [ ] Resources cleaned up (try-with-resources for `AutoCloseable`)?
- [ ] Memory monitored; no unbounded caches or collections?

## Handoffs

- → `sql-review` skill — for deep SQL / index analysis
- → `debug` skill — if the perf problem is actually a bug (e.g. infinite loop)
- → `refactor` skill — if optimization requires structural change
