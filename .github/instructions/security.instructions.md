---
description: 'OWASP Top 10 security rules for Java web applications.'
applyTo: '**/*.java, **/*.jsp'
---

# Security Rules

Secure by default. State what risk is mitigated when writing security code. SQL injection: `instructions/sql.instructions.md`. XSS: `instructions/jsp.instructions.md`.

## A01 Broken Access Control

- Deny by default; explicitly check rights per resource
- Allow-list for user-supplied URLs/paths; prevent path traversal

## A02 Cryptographic Failures

- Passwords: Argon2/bcrypt (never MD5/SHA-1); data at rest: AES-256; transit: HTTPS
- No hardcoded secrets — env vars or secret store

## A03 Injection

- SQL: `PreparedStatement` with `?` only
- OS command: argument-escaping libs; no shell concatenation
- XSS: `<c:out>` in JSP; context-aware encoding

## A04 Insecure Design

- Rate limiting on auth endpoints; account lockout on repeated failures
- No shared mutable state in servlets; business logic validation server-side

## A05 Security Misconfiguration

- Remove unused dependencies and default accounts before deploy
- Error pages: generic messages only — no stack traces or framework versions
- Security headers: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`

## A06 Vulnerable Components

- Pin dependency versions; no `SNAPSHOT` in production
- Track CVEs: `mvn versions:display-dependency-updates`

## A07 Authentication Failures

- New session ID on login; cookies: `HttpOnly` + `Secure` + `SameSite=Strict`

## A08 Integrity Failures

- Reject untrusted deserialization; prefer JSON over Java native serialization

## A09 Logging Failures

- Log all auth events and access control failures
- Sanitize log input (strip newlines, control chars)

## A10 SSRF

- Allow-list for hosts/ports/protocols on user-supplied URLs
- Block private IP ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `127.0.0.0/8`)

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| Stack trace in error response | Leaks internals (A05) | Log server-side; generic error to client |
| `new URL(userInput).openStream()` | SSRF (A10) | Allow-list hosts; block private IPs |
| No logging on failed logins | Brute-force undetected (A09) | Log with IP + timestamp |
| `ObjectInputStream.readObject()` on untrusted data | Deserialization RCE (A08) | Prefer JSON |
| Hardcoded credentials | First thing attackers try (A05) | Env vars / secret store |
