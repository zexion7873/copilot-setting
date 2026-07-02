---
description: 'Load when writing or auditing Java/JSP web code (Spring 3.2 + Hibernate 4.2, no Spring Boot) — OWASP Top 10. Triggers on: CSRF/session/cookie flags, BCrypt hashing (no MD5/SHA-1), XXE, ProcessBuilder command injection, SSRF, ObjectInputStream deserialization. Defer SQL injection to sql.instructions.md, XSS to jsp.instructions.md.'
applyTo: '**/*.java, **/*.jsp'
---

# Security Rules

Secure by default; name the mitigated risk. SQL injection: `instructions/sql.instructions.md`. XSS: `instructions/jsp.instructions.md`.

## A01 Broken Access Control

- Deny by default; explicit role/permission check per endpoint — logged-in never means allowed
- Allow-list user-supplied URLs/paths; prevent path traversal
- CSRF token on all state-changing POST forms — Spring Security 3.2 `<csrf>`; else double-submit cookie or synchronizer token
- State changes via POST/PUT/DELETE only, never GET; set `@RequestMapping(method = ...)` — omitting `method` matches every verb, bypassing CSRF tokens

## A02 Cryptographic Failures

- Passwords: bcrypt (`BCryptPasswordEncoder`, in Spring Security 3.2) or Argon2 (argon2-jvm — no native SS 3.2 encoder); never MD5/SHA-1. At rest: AES-256; transit: HTTPS
- No hardcoded secrets — env vars or secret store

## A03 Injection

- SQL: `PreparedStatement` with `?` only
- OS commands: `ProcessBuilder` with an argument list — never `Runtime.exec(String)` or `sh -c` with user input
- XSS: `<c:out>` in JSP; context-aware encoding
- XXE — disable DTDs/external entities on every XML parser via its own switch (they differ):
  - `DocumentBuilderFactory` / `SAXParserFactory`: `setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)` + `FEATURE_SECURE_PROCESSING`
  - `XMLInputFactory` (StAX, no `setFeature`): `setProperty(XMLInputFactory.SUPPORT_DTD, false)` + `setProperty("javax.xml.stream.isSupportingExternalEntities", false)`
  - JAXB `Unmarshaller` (no DTD switch): unmarshal via a `SAXSource` wrapping a hardened `XMLReader` as above

## A04 Insecure Design

- Rate-limit auth endpoints; account lockout on repeated failures
- No shared mutable servlet state; validate business logic server-side

## A05 Security Misconfiguration

- Remove unused dependencies and default accounts before deploy
- Error pages: generic only — no stack traces or framework versions
- Headers: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`

## A06 Vulnerable Components

- Pin versions; no `SNAPSHOT` in production
- CVE scan: OWASP Dependency-Check (`mvn org.owasp:dependency-check-maven:check`); `versions:display-dependency-updates` lists updates, not CVEs
- Spring 3.2 (EOL 2016) and Hibernate 4.2 (EOL 2015) carry unpatched CVEs — document as baseline risk in every audit

## A07 Authentication Failures

- New session ID on login; cookies `HttpOnly` + `Secure` + `SameSite=Strict` (Servlet 3.0 has no SameSite API — set via `Set-Cookie` header or container config)

## A08 Integrity Failures

- Reject untrusted deserialization; prefer JSON over Java native serialization

## A09 Logging Failures

- Log all auth events and access control failures; sanitize log input (strip newlines, control chars)

## A10 SSRF

- Allow-list hosts/ports/protocols on user-supplied URLs; block private, loopback, and link-local ranges: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `127.0.0.0/8`, `169.254.0.0/16` (covers `169.254.169.254` cloud metadata), IPv6 `::1` and `fc00::/7`

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `new URL(userInput).openStream()` | SSRF (A10) | Allow-list hosts; block private IPs |
| `ObjectInputStream.readObject()` on untrusted data | Deserialization RCE (A08) | Prefer JSON |
| No logging on failed logins | Brute-force undetected (A09) | Log with IP + timestamp |
| Unhardened `DocumentBuilderFactory` on user XML | XXE (A03) | `disallow-doctype-decl` = true (A03 config) |
