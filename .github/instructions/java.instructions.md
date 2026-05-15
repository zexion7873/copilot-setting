---
description: 'Java 8 language conventions — forbidden Java 9+ syntax, Optional usage, java.time over legacy Date/Calendar, Stream pitfalls, and lambda capture rules.'
applyTo: '**/*.java'
---

# Java 8 Language Conventions

Hard rules for Java 8 syntax and idioms. This file covers **language-level concerns only**. Related topics live elsewhere: `instructions/error-handling.instructions.md` (exception hierarchy and translation), `instructions/security-and-owasp.instructions.md` (input validation, XSS, OWASP), `instructions/self-explanatory-code-commenting.instructions.md` (commenting policy), `instructions/hibernate.instructions.md` (data access).

## Version Boundary — Forbidden Java 9+ Features

This codebase compiles on **JDK 8**. The following features were introduced in later releases and MUST NOT appear in source code:

| Feature | Introduced | Use instead |
|---|---|---|
| `var` (local-variable type inference) | 10 | Declare explicit types |
| Records | 14 | Plain POJO with explicit getters / `equals` / `hashCode` |
| Pattern matching for `instanceof` | 16 | Separate `instanceof` check, then cast |
| Pattern matching in `switch` | 21 | `if`/`else` chain |
| Sealed classes / interfaces | 17 | Not available — design around |
| Text blocks (`"""..."""`) | 13 | String concatenation across lines |
| Switch expressions | 14 | `switch` statements with `case ... break;` |
| `List.of` / `Map.of` / `Set.of` | 9 | `Collections.unmodifiableList(Arrays.asList(...))` |
| `Stream.toList()` | 16 | `collect(Collectors.toList())` |
| `Optional.ifPresentOrElse` / `or` / `stream` | 9 | `isPresent()` + `if`/`else` |
| `Stream.dropWhile` / `takeWhile` | 9 | Manual filter with a state flag |
| `String.repeat` / `isBlank` / `strip` | 11 | Manual loop or existing utility (e.g. Apache Commons `StringUtils`) |
| `Files.writeString` / `readString` | 11 | `Files.write(path, content.getBytes(UTF_8))` / `new String(Files.readAllBytes(path), UTF_8)` |
| `Collectors.teeing` | 12 | Split into two collector operations |

## Optional Usage

- **Return type only** — never as a field, never as a method parameter. `Optional` was designed for return values whose absence is meaningful.
- Never call `.get()` without an `isPresent()` check. Prefer `orElse(default)` / `orElseThrow(...)` / `orElseGet(supplier)`.
- Don't return `Optional<Collection>` — return an empty collection instead. Callers should never face two layers of emptiness.
- `Optional.of(x)` throws if `x` is null — use `Optional.ofNullable(x)` for nullable sources.
- Avoid nested `Optional<Optional<X>>` — flatten with `flatMap`.

## java.time over Date / Calendar

- Use `java.time` for all new date/time code:
  - `LocalDate` — date without time / zone
  - `LocalDateTime` — date + time without zone
  - `ZonedDateTime` — date + time + zone
  - `Instant` — UTC timestamp
  - `Duration` / `Period` — time spans
- Do NOT use `java.util.Date`, `java.util.Calendar`, or `java.text.SimpleDateFormat` in **new** code. Existing usages may remain until the surrounding code is touched.
- `SimpleDateFormat` is not thread-safe and is a frequent source of production bugs — never share an instance across threads.
- Formatting: `DateTimeFormatter` is immutable and thread-safe; safe to share as `static final`.
- Legacy boundary (JDBC, third-party libs that still require `Date`): convert at the boundary with `Date.from(instant)` / `instant.atZone(zone)`. Do not propagate `Date` inward.

## Streams

- Use streams for **transform / filter / reduce** pipelines. Use a `for` loop when the goal is "do something for each element" with side effects.
- Streams are **one-shot** — operating on the same `Stream` twice throws `IllegalStateException`.
- Default to **sequential** streams. `parallelStream()` requires benchmarking — splitting overhead and shared `ForkJoinPool.commonPool()` contention often make it slower in practice.
- `Stream.peek` is for debugging only. Don't use it for production side effects.
- `collect(Collectors.toList())` returns a list whose mutability is **unspecified**. Use `Collectors.toCollection(ArrayList::new)` if you need to mutate the result.

## Lambdas & Functional Interfaces

- Captured local variables must be **effectively final** — they cannot be reassigned after the lambda is created.
- Prefer **method references** when they read clearer: `String::trim` over `s -> s.trim()`. Don't force method references where the lambda is more readable.
- Lambdas cannot throw checked exceptions when the target functional interface doesn't declare them. Two acceptable approaches:
  - Design the interface to declare the checked exception (preferred for code you control).
  - Use a small wrapper utility that converts checked to unchecked at a clear boundary.
  Don't silently wrap every checked exception in `RuntimeException` — that erases the exception type.
- To modify outer state from a lambda: use `AtomicReference` / `AtomicInteger`, a single-element array, or restructure to collect the result.

## Concurrency Basics

- `CompletableFuture` for async composition. Don't block on `Future.get()` in business logic — chain with `thenCompose` / `thenApply`.
- `ConcurrentHashMap` over `Hashtable` or `Collections.synchronizedMap`.
- Prefer `java.util.concurrent.atomic` classes (`AtomicInteger`, `AtomicReference`, `LongAdder`) over `synchronized` blocks for simple counter / flag updates.
- Never share a `SimpleDateFormat` across threads — the fix is to switch to `DateTimeFormatter` (see java.time section).

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| Any Java 9+ feature from the Version Boundary table | Will not compile on JDK 8 | Use the Java 8 equivalent listed in the same row |
| `Optional<List<X>>` as return type | Caller has two emptiness checks (empty optional, empty list) — confusing | Return `List<X>`; use empty list for "no data" |
| `Optional` as method parameter | Forces every caller to wrap in `Optional.of(x)` — Optional wasn't designed for this | Overload the method, or accept nullable and check inside |
| `optional.get()` without `isPresent()` | `NoSuchElementException` at runtime | `orElse(default)` / `orElseThrow(SomeException::new)` |
| `private static final SimpleDateFormat FMT = ...` | Not thread-safe — race conditions on concurrent format/parse | `private static final DateTimeFormatter FMT = ...` (immutable, thread-safe) |
| `new Date()` / `new GregorianCalendar()` in new code | Mutable, timezone-confused, legacy API | `LocalDate.now()` / `Instant.now()` / `ZonedDateTime.now(zone)` |
| Re-using a `Stream` after a terminal operation | `IllegalStateException: stream has already been operated upon` | Create a fresh stream from the source each time |
| `.parallelStream()` without benchmarking | Splitting overhead and shared common pool often make it slower | Default to sequential; switch only after measuring |
| Mutating a captured variable inside a lambda | "Variable used in lambda should be final or effectively final" — won't compile | `AtomicReference` / single-element array, or restructure to collect a result |
| `collect(Collectors.toList())` followed by `.add(...)` | Mutability is not guaranteed by the spec | `collect(Collectors.toCollection(ArrayList::new))` when explicit mutability is needed |
| `stream.forEach(list::add)` to build a list | Unnecessary; mutable accumulator across the stream; less clear | `stream.collect(Collectors.toList())` |
| Wrapping every checked exception from a lambda in `RuntimeException` | Erases the exception type — callers can no longer distinguish failure modes | Declare the checked exception on the functional interface, or use a typed wrapper |
