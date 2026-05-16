---
name: security-audit
description: 'Use when user needs an OWASP-focused security audit of Java web code — injection, auth, access control, and configuration review. Triggers on: security audit, OWASP, vulnerability check, security review, 資安審查, 安全檢查, 有沒有漏洞, 資安. Produces severity-classified security findings. Do NOT use for general code review (prefer code-review), SQL-only review (prefer sql-review), or performance review (prefer performance).'
---

# Security Audit — Workflow

OWASP Top 10 focused audit. Security rules: `instructions/security.instructions.md`.

Full coding rules in `instructions/*.instructions.md`. Key rules (fallback for agent chat):

- **Java 8**: no `var`, no `List.of()`, no records — checked exceptions must be handled or declared
- **Spring 3.2**: XML config + `<tx:advice>` only, no `@Transactional`, no Spring Boot
- **Hibernate 4.2**: `getCurrentSession()` only, `hbm.xml` mappings, no JPA annotations
- **SQL (JDBC)**: `PreparedStatement` with `?` — zero string concatenation
- **SQL (HQL)**: named parameters (`:param`) — never concatenate into query strings
- **Security**: `<c:out>` for all JSP output; `HttpOnly` + `Secure` cookie flags

## Phase 1 — Map Attack Surface

1. Identify entry points: servlets, controllers, API endpoints, file uploads
2. Identify data flows: user input → processing → storage → output
3. Identify trust boundaries: authenticated vs public, admin vs user

## Phase 2 — Check by OWASP Category

For each entry point, check against A01–A10 from `instructions/security.instructions.md`:
- A01: broken access control — authorization on every resource, IDOR, path traversal
- A02: cryptographic failures — plaintext passwords, weak hashing, missing encryption for sensitive data
- A03: injection — SQL, OS command, XSS at every input boundary
- A04: insecure design — missing rate limiting, insufficient business logic validation
- A05: security misconfiguration — error stack leaks, default credentials, unnecessary features enabled
- A06: vulnerable components — outdated libraries with known CVEs
- A07: authentication & session — cookie flags (HttpOnly, Secure, SameSite), session fixation, credential storage
- A08: data integrity — unsafe deserialization, unsigned data, untrusted pipelines
- A09: logging & monitoring — missing audit trails, insufficient logging of security events
- A10: SSRF — server-side request forgery on any URL fetch

## Phase 3 — Classify Findings

| Severity | Criteria |
|---|---|
| 🔴 CRITICAL | Exploitable now; data breach or RCE possible |
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
