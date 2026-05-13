---
description: 'SLF4J + Logback logging conventions — severity levels, parameterized messages, context inclusion, and security.'
applyTo: '**/*.java'
---

# Logging Conventions

Hard rules for logging in Java 8 projects. Uses SLF4J facade with Logback implementation.

## Framework

- **SLF4J** facade only — never use `java.util.logging`, `System.out.println`, or `e.printStackTrace()` for logging.
- **Logback** as the implementation. Configuration lives in `logback.xml` or `logback-spring.xml`.
- Declare loggers as: `private static final Logger log = LoggerFactory.getLogger(MyClass.class);`

## Parameterized Messages

- **Always parameterized** — `log.info("User {} logged in from {}", userId, ip)`
- **Never concatenate** — `log.info("User " + userId + " logged in")` wastes allocation even when the level is disabled.
- For expensive computations, guard with level check: `if (log.isDebugEnabled()) { log.debug("state={}", computeExpensiveState()); }`

## Severity Levels

| Level | When to use | Example |
|---|---|---|
| `ERROR` | Needs human attention; system cannot recover automatically | DB connection pool exhausted, external service permanently down |
| `WARN` | Recoverable but unexpected; might need investigation | Retry succeeded after timeout, deprecated API still called |
| `INFO` | Business-significant events in normal operation | User login, order placed, batch job completed |
| `DEBUG` | Diagnostic detail for development and troubleshooting | Method entry/exit, intermediate calculation values, SQL parameters |

- **Production default: `INFO`**. `DEBUG` enabled per-package for troubleshooting only.
- Do not log expected conditions at `WARN` or above (e.g., user input validation failure is `DEBUG`, not `WARN`).

## Context

- Include identifying context in every log line: user ID, request ID, transaction ID, relevant parameters.
- Use MDC (Mapped Diagnostic Context) for cross-cutting identifiers: `MDC.put("requestId", requestId)` at the entry point, `MDC.remove("requestId")` at exit.
- Log the **outcome**, not just the attempt: `log.info("Order {} placed, total={}", orderId, total)` not `log.info("Placing order...")`.

## Security

- **Never log secrets** — passwords, tokens, API keys, session IDs, credit card numbers.
- **Never log PII without masking** — email, phone, SSN. If needed for debugging, mask: `log.debug("user email={}***", email.substring(0, 3))`.
- **Never log full request/response bodies** in production — they may contain sensitive data.

## Performance

- Minimize logging in hot paths. Log IDs and counts, not serialized collections.
- Structured (JSON) logs in production; human-readable pattern for local dev.

## Anti-Patterns

| Pattern | Fix |
|---|---|
| `System.out.println(...)` | `log.info(...)` — use the framework |
| `e.printStackTrace()` | `log.error("context", e)` — proper level and context |
| `log.error("Error: " + e.getMessage())` | `log.error("context", e)` — preserve stack trace, no concat |
| `log.info("entering method")` | Log outcomes, not ceremony |
| Log and rethrow same exception | Log at final handler only |
| `catch (Exception e) { log.warn(...); }` | Log + rethrow, or handle meaningfully |
