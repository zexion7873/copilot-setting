---
description: 'Load when writing or auditing Java/JSP web code (Spring 3.2 + Hibernate 4.2, no Spring Boot) — OWASP Top 10. Triggers on: CSRF/session/cookie flags, BCrypt hashing (no MD5/SHA-1), XXE, ProcessBuilder command injection, SSRF, ObjectInputStream deserialization. Defer SQL injection to sql.instructions.md, XSS to jsp.instructions.md.'
applyTo: '**/*.java, **/*.jsp'
---

# Security Rules

Secure by default. State what risk is mitigated when writing security code. SQL injection: `instructions/sql.instructions.md`. XSS: `instructions/jsp.instructions.md`.

## A01 Broken Access Control

- Deny by default; explicitly check rights per resource
- Authentication ≠ authorization: a logged-in user still needs an explicit role/permission check per endpoint — "logged in" never means "allowed"
- Allow-list for user-supplied URLs/paths; prevent path traversal
- CSRF: all state-changing POST forms must carry a CSRF token; Spring Security 3.2: configure `<csrf>` in security namespace; without Spring Security: manual double-submit cookie or synchronizer token
- State-changing operations via POST/PUT/DELETE only — never GET; restrict handlers with `@RequestMapping(method = ...)` (a mapping without `method` matches every verb and bypasses POST-form CSRF tokens)

## A02 Cryptographic Failures

- Passwords: bcrypt (`BCryptPasswordEncoder`, built-in to Spring Security crypto since 3.1, present in 3.2) or Argon2 (needs argon2-jvm — no native SS 3.2 encoder); never MD5/SHA-1. Data at rest: AES-256; transit: HTTPS
- No hardcoded secrets — env vars or secret store

## A03 Injection

- SQL: `PreparedStatement` with `?` only
- OS command: `ProcessBuilder` with an argument list — never `Runtime.exec(String)` or `sh -c` with user input; no shell-string concatenation
- XSS: `<c:out>` in JSP; context-aware encoding
- XXE: disable DTDs and external entities on every XML parser, using each API's own switch (they differ — `setFeature`/`disallow-doctype-decl` exists only on the first pair); critical in this XML-heavy stack:
  - `DocumentBuilderFactory` / `SAXParserFactory`: `setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)` plus `FEATURE_SECURE_PROCESSING`
  - `XMLInputFactory` (StAX): `setProperty(XMLInputFactory.SUPPORT_DTD, false)` and `setProperty("javax.xml.stream.isSupportingExternalEntities", false)` — it has no `setFeature`
  - JAXB `Unmarshaller`: no DTD switch of its own — unmarshal via a `SAXSource` wrapping a hardened `XMLReader` configured as above

## A04 Insecure Design

- Rate limiting on auth endpoints; account lockout on repeated failures
- No shared mutable state in servlets; business logic validation server-side

## A05 Security Misconfiguration

- Remove unused dependencies and default accounts before deploy
- Error pages: generic messages only — no stack traces or framework versions
- Security headers: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`

## A06 Vulnerable Components

- Pin dependency versions; no `SNAPSHOT` in production
- Track CVEs: OWASP Dependency-Check (`mvn org.owasp:dependency-check-maven:check`) — `versions:display-dependency-updates` only lists newer versions, it does not scan vulnerabilities
- Spring 3.2 (EOL 2016) and Hibernate 4.2 (EOL — final release 2015) carry unpatched CVEs — document as baseline risk in every audit

## A07 Authentication Failures

- New session ID on login; cookies: `HttpOnly` + `Secure` + `SameSite=Strict` (Servlet 3.0 has no SameSite API — set via `Set-Cookie` response header or container config)

## A08 Integrity Failures

- Reject untrusted deserialization; prefer JSON over Java native serialization

## A09 Logging Failures

- Log all auth events and access control failures
- Sanitize log input (strip newlines, control chars)

## A10 SSRF

- Allow-list for hosts/ports/protocols on user-supplied URLs
- Block private, loopback, and link-local ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `127.0.0.0/8`, `169.254.0.0/16` — link-local, covers the `169.254.169.254` cloud-metadata endpoint; IPv6 `::1` and `fc00::/7`)

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| Stack trace in error response | Leaks internals (A05) | Log server-side; generic error to client |
| `new URL(userInput).openStream()` | SSRF (A10) | Allow-list hosts; block private IPs |
| No logging on failed logins | Brute-force undetected (A09) | Log with IP + timestamp |
| `ObjectInputStream.readObject()` on untrusted data | Deserialization RCE (A08) | Prefer JSON |
| Hardcoded credentials | First thing attackers try (A05) | Env vars / secret store |
| `DocumentBuilderFactory.newInstance()` parsing user XML unhardened | XXE — file read, SSRF, DoS (A03) | `setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)` |
