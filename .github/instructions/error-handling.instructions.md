---
description: 'Exception handling and error response conventions for Java 8 — hierarchy, custom exceptions, retry, and error propagation.'
applyTo: '**/*.java'
---

# Exception Handling Conventions

Hard rules for error handling in Java 8 projects. Related rules in `copilot-instructions.md` (general), `instructions/security-and-owasp.instructions.md` (security), and `prompts/code-review-checklist.prompt.md` (review checklist) still apply — this file is the single source of truth for exception design and propagation.

## Exception Hierarchy

- **Unchecked (`RuntimeException`)** for programming errors — `IllegalArgumentException`, `IllegalStateException`, `NullPointerException`. Callers should not catch these; fix the bug instead.
- **Checked (`Exception`)** for recoverable conditions the caller can handle — I/O failures, external service errors, business rule violations. Force callers to decide how to handle.
- **Never catch `Throwable` or `Error`** — `OutOfMemoryError`, `StackOverflowError` are JVM-level and not recoverable.

## Custom Exceptions

- One base exception per module / bounded context (e.g., `OrderServiceException extends RuntimeException`).
- Subclass for distinct handling needs: `OrderNotFoundException`, `OrderAlreadyPaidException`.
- Always include:
  - A descriptive message with context: `"Order not found: orderId=" + orderId`
  - The original cause when wrapping: `new OrderServiceException("Failed to place order", cause)`
- Name exceptions for the problem, not the thrower: `InsufficientBalanceException` not `WalletServiceException`.

## Propagation Rules

- **Fail fast at boundaries** — validate inputs at the entry point (servlet, API handler, public method). Throw immediately on invalid input.
- **Trust internal calls** — do not defensively re-validate inside private methods called by already-validated public methods.
- **Handle at the right layer** — catch where you can meaningfully act (retry, fallback, translate). If you cannot act, let it propagate.
- **Translate at layer boundaries** — DAO throws `SQLException`, service catches and wraps as `DataAccessException`. Never leak implementation details upward.

| Layer | Catch | Translate to |
|---|---|---|
| DAO / Repository | `SQLException` | `DataAccessException` (unchecked) |
| Service | `DataAccessException`, domain exceptions | Business-level exception or rethrow |
| Controller / Servlet | All exceptions | HTTP error response (see below) |

## Error Response Format

At the outermost layer (servlet, API handler), convert exceptions to a consistent JSON response with machine-readable `error` code, human-readable `message`, and `timestamp`. Never expose stack traces or internal class names in responses — log them server-side at ERROR level. Clients switch on error codes, not messages.

## Empty Catch Blocks

**Forbidden.** If you genuinely must swallow an exception, add a comment explaining why AND log at DEBUG level. No silent swallowing.

## Retry Strategy

- Retry only on **transient** failures (network timeout, temporary unavailability). Never retry on validation errors or auth failures.
- **Bounded retries** — max 3 attempts with exponential backoff (`100ms`, `200ms`, `400ms`).
- **Idempotency** — only retry operations that are safe to repeat. Non-idempotent writes need deduplication (idempotency key).
- Log each retry attempt at WARN level with attempt number and cause.

## Resource Cleanup on Error Paths

- **`try-with-resources`** for all `AutoCloseable` instances (`InputStream`, `OutputStream`, etc.). JDBC resources (`Connection`, `PreparedStatement`, `ResultSet`) → see `instructions/sql-rules.instructions.md` §Java JDBC Resource Handling.
- Verify cleanup happens on ALL code paths, including early returns and exceptions in the middle of a multi-resource block.

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `catch (Exception e) {}` | Swallows all errors silently | Catch specific types; log or rethrow |
| `catch (Exception e) { throw new RuntimeException(e); }` | Loses context, generic wrapping | Use a domain-specific exception with message |
| `e.printStackTrace()` | Bypasses logging framework, leaks to stderr | `log.error("context", e)` |
| Catching and returning `null` | Caller gets NPE later with no trace | Throw or return `Optional` |
| Logging and rethrowing the same exception | Duplicate log entries | Log at the final handler only, or rethrow without logging |
| `throws Exception` on method signature | Forces callers to handle everything | Declare specific checked exceptions |
