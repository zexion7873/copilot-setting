---
description: 'Secure coding rules for Java web applications based on OWASP Top 10.'
applyTo: '**/*.java, **/*.jsp'
---

# Secure Coding and OWASP Guidelines

Code must be secure by default. When suggesting security-relevant code, state what risk is being mitigated. SQL injection rules live in `instructions/sql-rules.instructions.md`.

## A01 Broken Access Control

- Least privilege, deny by default — explicitly check rights against the resource being accessed
- Validate user-supplied URLs with allow-list for host/port/path
- Prevent path traversal — sanitize file paths from user input

## A02 Cryptographic Failures

- Argon2/bcrypt for password hashing (never MD5/SHA-1); AES-256 for data at rest; HTTPS for transit
- No hardcoded secrets — load from env vars or secret store

## A03 Injection

- SQL — see `instructions/sql-rules.instructions.md`
- OS command — use argument-escaping libs; no shell concatenation
- XSS — context-aware output encoding; `<c:out>` in JSP for all dynamic output

## A04 Insecure Design

- Rate limiting on authentication endpoints
- Account lockout after repeated failed attempts
- No shared mutable state in servlets (instance fields are shared across requests)
- Business logic validation server-side

## A07 Authentication Failures

- New session ID on login (prevent fixation)
- Cookies: `HttpOnly` + `Secure` + `SameSite=Strict`

## A08 Integrity Failures

- Reject untrusted deserialization; prefer JSON over Java native serialization
