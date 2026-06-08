---
name: security-audit
description: 'Use when user needs an OWASP-focused security audit of Java web code — injection, auth, access control, and configuration review. Triggers on: security audit, OWASP, vulnerability check, security review, 資安審查, 安全檢查, 有沒有漏洞, 資安. Produces severity-classified security findings. Do NOT use for general code review (prefer code-review), SQL-only review (prefer sql-review), or performance review (prefer performance).'
---

# Security Audit — Workflow

OWASP Top 10 focused audit. Security rules: `instructions/security.instructions.md`.

**Canonical rules — open the instruction files** (agent mode can read them directly):

- `instructions/security.instructions.md` — OWASP Top 10 for Java web
- `instructions/sql.instructions.md` — SQL injection, parameterization, JDBC resources
- `instructions/jsp.instructions.md` — JSP / JSTL output encoding, XSS
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

## Phase 1 — Map Attack Surface

1. Identify entry points: servlets, controllers, API endpoints, file uploads
2. Identify data flows: user input → processing → storage → output
3. Identify trust boundaries: authenticated vs public, admin vs user

## Phase 2 — Check by OWASP Category

For each entry point, trace data flow from input → processing → storage → output and check:

**A01 Broken Access Control** (check each):
- [ ] Every endpoint enforces role/permission — not just login check
- [ ] Object references (ID in URL/param) validated against current user's ownership (IDOR)
- [ ] No path traversal: file paths from user input sanitized
- [ ] HTTP method restrictions enforced (POST-only for mutations)
- [ ] CSRF: all state-changing POST forms carry a CSRF token (Spring Security 3.2 `<csrf>` config or manual token+session check)

**A02 Cryptographic Failures** (check each):
- [ ] Passwords hashed with bcrypt (native `BCryptPasswordEncoder`) or Argon2 (needs argon2-jvm) — never plaintext, MD5, or SHA1
- [ ] Sensitive data encrypted at rest and in transit
- [ ] No secrets in logs, error messages, or client responses
- [ ] No hardcoded credentials in source or config — search for password/secret/apikey/token literals

**A03 Injection** (check each):
- [ ] SQL: all queries parameterized — search for string concat near `createQuery`/`createSQLQuery`/`PreparedStatement`
- [ ] HQL: named parameters `:param` only — no `"... where x = '" + input + "'"`
- [ ] OS command: no `Runtime.exec()` or `ProcessBuilder` with user input
- [ ] XSS: every JSP variable in `<c:out>` — search for `${` without encoding
- [ ] XXE: every XML parser of user-supplied input disables DTDs / external entities — search for `DocumentBuilderFactory` / `SAXParserFactory` / `XMLInputFactory` / `Unmarshaller` without `disallow-doctype-decl`

**A04 Insecure Design** (check each):
- [ ] Rate limiting on login/registration/password-reset
- [ ] Business logic validation not bypassable by skipping steps

**A05 Security Misconfiguration** (check each):
- [ ] Error responses don't leak stack traces or internal paths
- [ ] No default credentials or debug endpoints in production config

**A06 Vulnerable Components** (check each):
- [ ] Key dependencies (Spring, Hibernate, Jackson, Log4j, Commons) not on known-CVE versions
- [ ] Run `mvn org.owasp:dependency-check-maven:check` or `mvn versions:display-dependency-updates` and flag any CVE
- [ ] Spring 3.2 and Hibernate 4.2 are EOL — document known unpatched CVEs as baseline risk

**A07 Auth & Session** (check each):
- [ ] Cookie flags: `HttpOnly`, `Secure`, `SameSite=Strict`
- [ ] Session ID regenerated after login (fixation prevention)
- [ ] Login endpoint has brute-force protection

**A08–A10** (check if applicable):
- [ ] No unsafe deserialization of user-controlled data (A08)
- [ ] Security events logged with sufficient detail for forensics (A09)
- [ ] No server-side URL fetch with user-controlled target (A10/SSRF)

## Phase 3 — Classify Findings

| Severity | Criteria |
|---|---|
| 🔴 CRITICAL | Exploitable now; data breach or RCE possible (e.g., SQL injection, XXE, unsafe deserialization) |
| 🟠 HIGH | Exploitable with moderate effort |
| 🟡 MEDIUM | Defense-in-depth gap; not directly exploitable |
| ⚪ LOW | Best practice deviation; minimal risk |

## Phase 4 — Report

For each finding:
```
[SEVERITY] A0N — <title>
Location: <file:line>
Issue: <what's wrong>
Exploit: <how an attacker would use this>
Fix: <specific remediation>
```

## Handoffs

- → `@implementer` — to fix security findings
- ← `@reviewer` — when security mode is activated
- ← `code-review` skill — when code review finds security concerns
- ← `code-review` skill — if POM CVE finding needs runtime exploit verification
