---
applyTo: '**/*.java, **/*.jsp'
description: "Secure coding rules for Java web applications based on OWASP Top 10 and industry best practices."
---
# Secure Coding and OWASP Guidelines

Code generated, reviewed, or refactored must be secure by default. When suggesting security-relevant code, **state what risk is being mitigated** (e.g., "parameterized query prevents SQL injection").

### A01 Broken Access Control & A10 SSRF
- **Least privilege, deny by default** — explicitly check rights against the resource being accessed
- **Validate user-supplied URLs** (webhooks etc.) with allow-list for host/port/path
- **Prevent path traversal** — sanitize file paths from user input; use safe path-building APIs

### A02 Cryptographic Failures
- **Strong algorithms only** — Argon2/bcrypt for password hashing (never MD5/SHA-1); AES-256 for data at rest; HTTPS for transit
- **No hardcoded secrets** — load from env vars or secret store (Vault, AWS Secrets Manager)

### A03 Injection
- **Parameterized queries only** — never build SQL by string concatenation
- **Safe shell APIs** — use argument-escaping libs for OS commands (no shell concat)
- **XSS** — context-aware output encoding; prefer `.textContent` over `.innerHTML`; sanitize with DOMPurify when HTML is required

### A05/A06 Misconfiguration & Vulnerable Components
- Disable verbose errors/debug in production
- Set `Content-Security-Policy`, `Strict-Transport-Security`, `X-Content-Type-Options`
- Pin latest stable dependency versions; remind to run `npm audit` / `pip-audit` / Snyk

### A07 Authentication Failures
- Issue a new session ID on login (prevent fixation); cookies must be `HttpOnly` + `Secure` + `SameSite=Strict`
- Rate-limit and lock out brute-force attempts on auth and password-reset

### A08 Integrity Failures
- Reject untrusted deserialization without validation; prefer JSON over Pickle/Java native; enforce strict type checking
