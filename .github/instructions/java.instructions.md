---
description: 'Java 8 language conventions — forbidden Java 9+ syntax, Optional usage, java.time over legacy Date/Calendar, Stream pitfalls, and lambda capture rules.'
applyTo: '**/*.java'
---

# Java 8 Language Conventions

Language-level rules only. Exception hierarchy → `instructions/error-handling.instructions.md`; security → `instructions/security-and-owasp.instructions.md`; comments → `instructions/self-explanatory-code-commenting.instructions.md`; data access → `instructions/hibernate.instructions.md`.

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

- Return type only — never field, never parameter.
- Never `.get()` without `isPresent()` — use `orElse` / `orElseThrow` / `orElseGet`.
- Never `Optional<Collection>` — return an empty collection.
- `Optional.of(x)` throws on null; use `Optional.ofNullable(x)` for nullable sources.
- No nested `Optional<Optional<X>>` — flatten with `flatMap`.

## java.time over Date / Calendar

- New date/time code uses `java.time` — `LocalDate`, `LocalDateTime`, `ZonedDateTime`, `Instant`, `Duration`, `Period`.
- Do NOT use `java.util.Date` / `Calendar` / `SimpleDateFormat` in new code (existing usages stay until touched).
- `SimpleDateFormat` is **not thread-safe** — never share an instance across threads. Use `DateTimeFormatter` (immutable, safe as `static final`).
- Legacy boundary (JDBC, third-party libs): convert at the boundary with `Date.from(instant)` / `instant.atZone(zone)` — don't propagate `Date` inward.

## Streams

- Transform / filter / reduce only — not side effects (use `for` for those).
- One-shot — never reuse a `Stream` (throws `IllegalStateException`).
- Default sequential; `parallelStream()` only after benchmarking.
- `Stream.peek` for debugging only.
- `collect(Collectors.toList())` mutability is unspecified — use `Collectors.toCollection(ArrayList::new)` when mutability is required.

## Lambdas

- Captured variables must be effectively final.
- Method references when clearer (`String::trim` vs `s -> s.trim()`); lambdas when not.
- Checked exceptions in lambdas: declare on the functional interface, or use a typed wrapper utility — don't silently wrap in `RuntimeException`.

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `Optional<List<X>>` as return type | Caller has two emptiness checks (empty optional, empty list) | Return `List<X>`; empty list for "no data" |
| `Optional` as method parameter | Forces callers to wrap in `Optional.of(x)` | Overload the method, or accept nullable and check inside |
| `optional.get()` without `isPresent()` | `NoSuchElementException` at runtime | `orElse(default)` / `orElseThrow(SomeException::new)` |
| `private static final SimpleDateFormat FMT = ...` | Not thread-safe — race conditions on concurrent format/parse | `private static final DateTimeFormatter FMT = ...` |
| `new Date()` / `new GregorianCalendar()` in new code | Mutable, timezone-confused, legacy API | `LocalDate.now()` / `Instant.now()` / `ZonedDateTime.now(zone)` |
| Mutating a captured variable inside a lambda | "Variable used in lambda should be final or effectively final" — won't compile | `AtomicReference` / single-element array, or restructure to collect a result |
| Wrapping every checked exception from a lambda in `RuntimeException` | Erases the exception type — callers can't distinguish failure modes | Declare the checked exception on the functional interface, or use a typed wrapper |
