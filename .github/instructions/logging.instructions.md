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
