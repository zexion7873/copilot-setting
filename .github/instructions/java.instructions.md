---
description: 'Load when writing or reviewing .java code — Java 8 version-lock floor: syntax, exceptions, logging, concurrency. Triggers on: var, records, text blocks, List.of/Map.of, pattern matching, java.time, BigDecimal, SLF4J. Forces Java 8, not modern Java. Defer SQL/Spring/JSP to their files.'
applyTo: '**/*.java'
---

# Java 8 Conventions

Java 8 only — AI models default to modern Java; correct that bias. If unsure a symbol exists in Java 8, verify here — never guess.

## Language Boundary (Java 9+ Forbidden)

- `var`, records, sealed classes, text blocks, pattern matching, module system (`module-info.java`)
- `List.of()`, `Map.of()`, `Set.of()` — use `Arrays.asList()` / `Collections.unmodifiableMap()`; `Arrays.asList` is fixed-size but element-mutable and allows nulls — wrap in `Collections.unmodifiableList` for true immutability
- `String.isBlank()`, `String.strip()` — use `StringUtils` or `.trim().isEmpty()`
- `Optional.ifPresentOrElse()`, `Optional.stream()`
- `try-with-resources` on a pre-declared effectively-final variable (Java 9) — declare the resource inside `try (...)`; the construct is Java 7 and stays mandatory for JDBC (`instructions/sql.instructions.md`)

## Optional

- Return type only — never field, parameter, or collection element
- `orElse()` for cheap defaults; `orElseGet()` for expensive computation
- `orElseThrow(() -> new ...)` over `.get()`; no-arg `orElseThrow()` is Java 10+

## Streams

- One operation per line; break chain at `.collect()`
- Never mutate external state in `forEach` / `map` / `filter`; prefer `for` loops for simple side effects

## Date and Time

- Use `java.time` (`LocalDate`, `LocalDateTime`, `ZonedDateTime`, `Instant`, `Duration`) for business logic
- **Two hard exceptions** (Hibernate 4.2 and JSTL 1.2 `<fmt:formatDate>` lack `java.time` support): hbm.xml-mapped entity date fields stay `java.util.Date` / `java.sql.Timestamp` (no Hibernate 4.2 type — fails or persists as a serialized BLOB); dates passed to a JSP for `<fmt:formatDate>` stay `java.util.Date` (`instructions/jsp.instructions.md`)
- Convert at the service boundary: `Date.from(instant)` / `date.toInstant()`
- Avoid `java.util.Calendar` in new code

## Numbers & Money

- Money / any exact decimal → `BigDecimal`; never `double` or `float`
- Construct from `String`: `new BigDecimal("0.1")`, never `new BigDecimal(0.1)` (binary float error)
- Compare with `compareTo() == 0`, not `equals()` — `2.0` ≠ `2.00` under `equals()`

## Concurrency

- Servlets, Spring singletons, and DAOs must be **stateless** — no shared mutable instance fields
- Shared mutable data → `ConcurrentHashMap` / `Atomic*` / explicit `synchronized`; never a bare `HashMap` across threads
- Prefer `final` fields and immutability over locking; `volatile` for visibility flags

## Exception Handling

- **Unchecked** for programming errors; **Checked** for recoverable conditions
- Never catch `Throwable` or `Error`; empty catch blocks forbidden — handle, rethrow, or log at DEBUG with justification
- Always chain cause: `throw new ServiceException("msg", original)`
- Translate at layer boundaries: DAO → `DataAccessException`, service → business exception, controller → HTTP error
- Never expose stack traces in HTTP responses

## Logging (SLF4J)

- `private static final Logger log = LoggerFactory.getLogger(MyClass.class);`
- Parameterized only, never `+` concatenation; exception as last arg: `log.error("Failed order {}", orderId, e)`
- Never log secrets, tokens, PII, or full request/response bodies
- ERROR = needs human attention; WARN = unexpected but recoverable; INFO = business events; DEBUG = diagnostics

## Code Style

- Comments explain WHY, not WHAT; delete commented-out code; extract a method when it stops doing one thing (~30 lines is a smell, not a cap)

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `List.of("a", "b")` | Java 9+ — won't compile | `Arrays.asList("a", "b")` |
| `System.out.println(...)` | No levels, lost in production | `log.debug(...)` via SLF4J |
| `log.info("User " + userId)` | Runs even when level disabled | `log.info("User {}", userId)` |
| `catch (Exception e) { return null; }` | Converts to NPE elsewhere | Rethrow or `Optional.empty()` |
| `double price = 19.99` for money | Binary float rounding | `new BigDecimal("19.99")` |
