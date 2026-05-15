---
description: 'SLF4J + Logback logging conventions — parameterized messages, severity levels, and security.'
applyTo: '**/*.java'
---

# Logging Conventions

Hard rules for logging in Java 8 projects using SLF4J + Logback.

## Framework

- SLF4J facade only — never `System.out.println` or `e.printStackTrace()`.
- Declare: `private static final Logger log = LoggerFactory.getLogger(MyClass.class);`

## Parameterized Messages

- Always: `log.info("User {} logged in from {}", userId, ip)`
- Never concatenate: `log.info("User " + userId + " logged in")`
- Guard expensive computations: `if (log.isDebugEnabled()) { ... }`

## Severity Levels

- `ERROR` — needs human attention, system cannot self-recover
- `WARN` — recoverable but unexpected, might need investigation
- `INFO` — business-significant events in normal operation (production default)
- `DEBUG` — diagnostic detail, enabled per-package for troubleshooting only

Do not log expected conditions (e.g., input validation failure) at WARN or above.

## Context

- Include identifying context: user ID, request ID, relevant parameters.
- Use MDC for cross-cutting identifiers.
- Log the **outcome**, not just the attempt.

## Security

- Never log secrets, tokens, API keys, session IDs, or PII.
- Never log full request/response bodies in production.

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `System.out.println("debug: " + value)` | No levels, no context, not configurable, lost in production | `log.debug("value={}", value)` via SLF4J |
| `log.info("User " + userId + " logged in")` | String concatenation runs even when level is disabled; wastes CPU | `log.info("User {} logged in", userId)` parameterized |
| `log.error("Failed", e.getMessage())` | Loses stack trace; `getMessage()` is often `null` | `log.error("Failed to process order {}", orderId, e)` — exception as last arg |
| `log.warn("Invalid input")` on expected validation failure | Floods logs with noise at WARN; obscures real warnings | `log.debug(...)` or omit — validation failures are normal flow |
| `log.info("token={}", apiKey)` | Leaks secrets into log files accessible to operations staff | Never log secrets, tokens, session IDs, or PII |
| `e.printStackTrace()` | Bypasses SLF4J; output goes to stderr without timestamp or context | `log.error("Context message", e)` |
