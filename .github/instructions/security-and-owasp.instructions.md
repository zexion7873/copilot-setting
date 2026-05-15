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

## A05 Security Misconfiguration

- Remove unused dependencies, sample apps, and default accounts before deployment
- Error pages must not expose stack traces, framework versions, or internal paths — return generic messages
- Disable directory listing and unnecessary HTTP methods (`TRACE`, `OPTIONS` where not needed)
- Set security headers: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Content-Security-Policy`
- Review `web.xml` security constraints on every release

## A06 Vulnerable and Outdated Components

- Track dependency versions — `mvn versions:display-dependency-updates` periodically
- Pin dependency versions in `pom.xml`; never use `SNAPSHOT` in production builds
- Remove unused dependencies — each unused JAR is an unmonitored attack surface
- Subscribe to CVE feeds (NVD, GitHub Advisories) for direct dependencies

## A08 Integrity Failures

- Reject untrusted deserialization; prefer JSON over Java native serialization

## A09 Security Logging and Monitoring Failures

- Log all authentication events: successful login, failed login, logout, password change
- Log access control failures (unauthorized resource access attempts)
- Log input validation failures server-side — these are potential probing attempts
- Sanitize log input to prevent log injection (strip newlines, control characters)
- Ensure alerting exists for suspicious patterns: repeated failed logins, unusual access times, privilege escalation attempts

## A10 Server-Side Request Forgery (SSRF)

- Validate and sanitize all user-supplied URLs before fetching remote resources
- Use an allow-list for permitted hosts, ports, and protocols
- Block requests to private/internal IP ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`, `127.0.0.0/8`)
- Do not follow redirects from user-supplied URLs without re-validating the target

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `e.printStackTrace()` in servlet error page | Leaks internal class names and paths to attacker (A05) | Log server-side; return generic error to client |
| Hardcoded `admin`/`admin` or default credentials | First thing attackers try on any deployment (A05) | Load from env vars / secret store; rotate on deploy |
| `new URL(userInput).openStream()` without validation | SSRF — attacker probes internal network or cloud metadata (A10) | Allow-list hosts; block private IP ranges; validate scheme |
| No logging on failed login attempts | Brute-force attacks go undetected (A09) | Log every failed attempt with IP, timestamp, and username |
| Using a dependency with known CVE in `pom.xml` | Exploitable vulnerability shipped to production (A06) | Run `mvn versions:display-dependency-updates`; patch or replace |
| `ObjectInputStream.readObject()` on untrusted input | Deserialization RCE — arbitrary code execution (A08) | Prefer JSON; if unavoidable, use look-ahead deserialization filter |
| Catching security exception and continuing | Bypasses access control; attacker proceeds as if authorized (A01) | Let security exceptions propagate; deny by default |
