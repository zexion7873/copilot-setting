---
description: 'Secure coding rules for Java web applications based on OWASP Top 10 and industry best practices.'
applyTo: '**/*.java, **/*.jsp'
---

# Secure Coding and OWASP Guidelines

Code generated, reviewed, or refactored must be secure by default. When suggesting security-relevant code, **state what risk is being mitigated** (e.g., "parameterized query prevents SQL injection"). SQL injection rules live in `instructions/sql-rules.instructions.md`. Security logging rules also apply from `instructions/logging.instructions.md` (A09).

## A01 Broken Access Control & A10 SSRF

- **Least privilege, deny by default** — explicitly check rights against the resource being accessed
- **Validate user-supplied URLs** (webhooks etc.) with allow-list for host/port/path
- **Prevent path traversal** — sanitize file paths from user input; use safe path-building APIs

## A02 Cryptographic Failures

- **Strong algorithms only** — Argon2/bcrypt for password hashing (never MD5/SHA-1); AES-256 for data at rest; HTTPS for transit
- **No hardcoded secrets** — load from env vars or secret store (Vault, AWS Secrets Manager)

## A03 Injection

- **SQL injection** — see `instructions/sql-rules.instructions.md` for full parameterization rules
- **OS command injection** — use argument-escaping libs; no shell concatenation
- **XSS** — context-aware output encoding; prefer `.textContent` over `.innerHTML`; sanitize with DOMPurify when HTML is required

## A04 Insecure Design

- **Rate limiting** on authentication endpoints and sensitive operations — absence of rate limiting is itself a finding
- **Account lockout** after repeated failed login attempts; log lockout events for monitoring
- **No shared mutable state** in servlets — instance fields in `HttpServlet` subclasses are shared across all requests (servlet singleton)
- **Business logic validation server-side** — never trust client-side checks alone; validate constraints, ownership, and authorization at the server

## A05/A06 Misconfiguration & Vulnerable Components

- Disable verbose errors/debug in production
- Set `Content-Security-Policy`, `Strict-Transport-Security`, `X-Content-Type-Options`
- Pin latest stable dependency versions; remind to run `npm audit` / `pip-audit` / Snyk

## A07 Authentication Failures

- Issue a new session ID on login (prevent fixation); cookies must be `HttpOnly` + `Secure` + `SameSite=Strict`
- Rate-limit and lock out brute-force attempts on auth and password-reset

## A08 Integrity Failures

- Reject untrusted deserialization without validation; prefer JSON over Pickle/Java native; enforce strict type checking

## A09 Security Logging & Monitoring Failures

- **Log all authentication events** — login success, login failure, account lockout, password reset request
- **Log authorization failures** — access denied with user ID, requested resource, and action attempted
- **Structured security logs** — include timestamp, user ID, source IP, action, resource, and result; use a dedicated security logger or marker
- **Never log secrets or PII** — mask tokens, passwords, session IDs, and credit card numbers in all log output
- **Tamper-evident log storage** — write security logs to append-only storage; alert on log gaps or deletion
