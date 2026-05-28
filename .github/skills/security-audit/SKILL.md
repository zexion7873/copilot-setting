---
name: security-audit
description: 'Use when user needs an OWASP-focused security audit of Java web code — injection, auth, access control, and configuration review. Triggers on: security audit, OWASP, vulnerability check, security review, 資安審查, 安全檢查, 有沒有漏洞, 資安. Produces severity-classified security findings. Do NOT use for general code review (prefer code-review), SQL-only review (prefer sql-review), or performance review (prefer performance).'
---

# Security Audit — Workflow

OWASP Top 10 focused audit. Security rules: `instructions/security.instructions.md`.

**Canonical rules — open the instruction files** (agent mode can read them directly):

- `instructions/security.instructions.md` — OWASP Top 10 for Java web
- `instructions/jsp.instructions.md` — JSP / JSTL output encoding, XSS
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

If you cannot open files, Key rules (fallback for agent chat):

- **Injection**: `PreparedStatement` / `:named` params; `<c:out>` for all JSP output
- **Auth & session**: new session ID on login; `HttpOnly` + `Secure` + `SameSite=Strict` cookies
- **Exposure**: no stack traces in responses; deny-by-default access control
- **Cryptography**: Argon2/bcrypt for passwords (never MD5/SHA-1); AES-256 at rest; no hardcoded secrets
- **SSRF / deserialization**: allow-list hosts/ports for user-supplied URLs; reject untrusted `ObjectInputStream`

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
