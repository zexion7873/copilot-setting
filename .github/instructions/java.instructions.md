---
description: 'Load when writing or reviewing .java code — Java 8 version-lock floor: syntax, exceptions, logging, concurrency. Triggers on: var, records, text blocks, List.of/Map.of, pattern matching, java.time, BigDecimal, SLF4J. Forces Java 8, not modern Java. Defer SQL/Spring/JSP to their files.'
applyTo: '**/*.java'
---

# Java 8 Conventions

This project is Java 8. AI models default to modern Java, and that pull is strong — treat it as a bias to correct, not a preference to follow. A newer-version symbol does not fail at review, it fails at `mvn compile`; if you are not certain something exists in Java 8, verify against this file before writing it — never guess.

## Language Boundary (Java 9+ Forbidden)

- `var`, records, sealed classes, text blocks, pattern matching
- `List.of()`, `Map.of()`, `Set.of()` — use `Arrays.asList()` / `Collections.unmodifiableMap()` (note: `Arrays.asList` is fixed-size but element-mutable and allows nulls, unlike `List.of` — wrap in `Collections.unmodifiableList` when true immutability matters)
- `String.isBlank()`, `String.strip()` — use `StringUtils` or `.trim().isEmpty()`
- `Optional.ifPresentOrElse()`, `Optional.stream()`
- Module system (`module-info.java`)
- `try-with-resources` on a pre-declared effectively-final variable (Java 9) — declare the resource *inside* the `try (...)` parentheses instead; try-with-resources itself is Java 7 and stays mandatory for JDBC (`instructions/sql.instructions.md`)

## Optional

- Return type only — never field, parameter, or collection element
- `orElse()` for cheap defaults; `orElseGet()` for expensive computation
- `orElseThrow(SomeException::new)` over `.get()` — `.get()` throws cryptic `NoSuchElementException`. Note: Java 8 requires the supplier form `orElseThrow(() -> new ...)` — the no-arg `orElseThrow()` is Java 10+.

## Streams

- One operation per line; break chain at `.collect()`
- Never modify external state inside `forEach` / `map` / `filter`
- Prefer `for` loop for simple iterations with side effects

## Date and Time

- Use `java.time` (`LocalDate`, `LocalDateTime`, `ZonedDateTime`, `Instant`, `Duration`) for business logic, computation, and internal date handling — a Java 8 feature and the default for new code
- **Two hard exceptions on this stack** — Hibernate 4.2 has no `java.time` support (that arrived in Hibernate 5's `hibernate-java8` module) and JSTL 1.2 `<fmt:formatDate>` accepts only `java.util.Date`:
  - hbm.xml-mapped entity date fields stay `java.util.Date` / `java.sql.Timestamp` — a `LocalDateTime` field has no Hibernate 4.2 type mapping (fails, or silently persists as a serialized BLOB)
  - dates passed to a JSP for `<fmt:formatDate>` stay `java.util.Date` (`instructions/jsp.instructions.md`)
- Convert at the service boundary with `Date.from(instant)` / `Date.toInstant()` between `java.time` logic and the persistence / view layers
- Still avoid `java.util.Calendar` (mutable, error-prone) in new code

## Numbers & Money

- Money / currency / any exact decimal → `BigDecimal`; never `double` or `float`
- Construct from `String`: `new BigDecimal("0.1")`, never `new BigDecimal(0.1)` (captures binary float error)
- Compare with `compareTo() == 0`, not `equals()` — `2.0` and `2.00` are unequal under `equals()`

## Concurrency

- Servlets, Spring singletons, and DAOs must be **stateless** — no shared mutable instance fields
- Shared mutable data → `ConcurrentHashMap` / `Atomic*` / explicit `synchronized`; never a bare `HashMap` across threads
- Prefer `final` fields and immutability over locking; `volatile` for cross-thread visibility flags

## Exception Handling

- **Unchecked** (`RuntimeException`) for programming errors; **Checked** for recoverable conditions
- Never catch `Throwable` or `Error`
- Empty catch blocks forbidden — handle, rethrow, or log at DEBUG with justification
- Always chain cause: `throw new ServiceException("msg", original)`
- Translate at layer boundaries: DAO → `DataAccessException`, Service → business exception, Controller → HTTP error
- Never expose stack traces in HTTP responses

## Logging (SLF4J)

- `private static final Logger log = LoggerFactory.getLogger(MyClass.class);`
- Parameterized only: `log.info("User {} logged in", userId)` — never `+` concatenation
- Exception as last arg: `log.error("Failed order {}", orderId, e)`
- Never log secrets, tokens, PII, or full request/response bodies
- ERROR = needs human attention; WARN = unexpected but recoverable; INFO = business events; DEBUG = diagnostics

## Code Style

- Comments explain WHY, not WHAT — code should be self-explanatory
- Delete commented-out code; that's what git is for
- Extract a method when it stops doing one thing — past ~30 lines of logic is a smell to look at, not a hard cap

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `var result = ...` | Java 9+ — won't compile | Explicit type declaration |
| `List.of("a", "b")` | Java 9+ — won't compile on Java 8 | `Arrays.asList("a", "b")` |
| `catch (Throwable t) { }` | Catches unrecoverable `Error`s; empty body swallows | Catch specific exception; never empty body |
| `log.info("User " + userId)` | Concatenation runs even when level disabled | `log.info("User {}", userId)` |
| `System.out.println(...)` | Unstructured, no levels, lost in production | `log.debug(...)` via SLF4J |
| `throw new RuntimeException("err")` without cause | Loses original stack trace | `throw new RuntimeException("msg", original)` |
| `catch (Exception e) { return null; }` | Converts to NPE elsewhere | Rethrow meaningful exception or `Optional.empty()` |
| `new Date()` / `Calendar.getInstance()` in business logic | Legacy mutable API | `java.time` (`LocalDateTime.now()` etc.) — but hbm.xml entity date fields & `<fmt:formatDate>` inputs must stay `java.util.Date` (Hibernate 4.2 / JSTL 1.2 lack java.time) |
| `double price = 19.99` for money | Binary float rounding errors | `new BigDecimal("19.99")` |
| Shared `HashMap` mutated by servlet threads | Race condition; lost updates | `ConcurrentHashMap` or confine to method scope |
