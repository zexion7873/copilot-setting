---
description: 'Java 8 language rules — forbidden syntax, exception handling, logging, and code style.'
applyTo: '**/*.java'
---

# Java 8 Conventions

This project is Java 8. AI models default to modern Java — correct that here.

## Language Boundary (Java 9+ Forbidden)

- `var`, records, sealed classes, text blocks, pattern matching
- `List.of()`, `Map.of()`, `Set.of()` — use `Arrays.asList()`, `Collections.unmodifiableMap()`
- `String.isBlank()`, `String.strip()` — use `StringUtils` or `.trim().isEmpty()`
- `Optional.ifPresentOrElse()`, `Optional.stream()`
- Module system (`module-info.java`)
- `try-with-resources` on effectively-final variables (Java 9 feature)

## Optional

- Return type only — never field, parameter, or collection element
- `orElse()` for cheap defaults; `orElseGet()` for expensive computation
- `orElseThrow()` over `.get()` — `.get()` throws cryptic `NoSuchElementException`

## Streams

- One operation per line; break chain at `.collect()`
- Never modify external state inside `forEach` / `map` / `filter`
- Prefer `for` loop for simple iterations with side effects

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

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `var result = ...` | Java 9+ — won't compile | Explicit type declaration |
| `List.of("a", "b")` | Java 9+ | `Arrays.asList("a", "b")` |
| `catch (Throwable t) { }` | Catches unrecoverable `Error`s; empty body swallows | Catch specific exception; never empty body |
| `log.info("User " + userId)` | Concatenation runs even when level disabled | `log.info("User {}", userId)` |
| `System.out.println(...)` | Unstructured, no levels, lost in production | `log.debug(...)` via SLF4J |
| `throw new RuntimeException("err")` without cause | Loses original stack trace | `throw new RuntimeException("msg", original)` |
| `catch (Exception e) { return null; }` | Converts to NPE elsewhere | Rethrow meaningful exception or `Optional.empty()` |
