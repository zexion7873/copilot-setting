---
description: 'Exception handling and error response conventions for Java 8 — hierarchy, custom exceptions, and error propagation.'
applyTo: '**/*.java'
---

# Exception Handling Conventions

Hard rules for error handling in Java 8 projects.

## Exception Hierarchy

- **Unchecked (`RuntimeException`)** for programming errors — `IllegalArgumentException`, `IllegalStateException`. Callers should not catch these; fix the bug instead.
- **Checked (`Exception`)** for recoverable conditions the caller can handle — I/O failures, external service errors, business rule violations.
- **Never catch `Throwable` or `Error`** — `OutOfMemoryError`, `StackOverflowError` are not recoverable.

## Custom Exceptions

- One base exception per module (e.g., `OrderServiceException extends RuntimeException`).
- Subclass for distinct handling needs: `OrderNotFoundException`, `OrderAlreadyPaidException`.
- Always include a descriptive message with context and the original cause when wrapping.
- Name exceptions for the problem, not the thrower.

## Propagation Rules

- **Fail fast at boundaries** — validate inputs at the entry point. Throw immediately on invalid input.
- **Handle at the right layer** — catch where you can meaningfully act (retry, fallback, translate). Otherwise let it propagate.
- **Translate at layer boundaries** — DAO throws `SQLException`, service wraps as `DataAccessException`. Never leak implementation details upward.

| Layer | Catch | Translate to |
|---|---|---|
| DAO / Repository | `SQLException` | `DataAccessException` (unchecked) |
| Service | `DataAccessException`, domain exceptions | Business-level exception or rethrow |
| Controller / Servlet | All exceptions | HTTP error response |

## Error Response Format

At the outermost layer, convert exceptions to a consistent JSON response with machine-readable `error` code, human-readable `message`, and `timestamp`. Never expose stack traces or internal class names in responses.

## Empty Catch Blocks

**Forbidden.** If you genuinely must swallow an exception, add a comment explaining why AND log at DEBUG level.
