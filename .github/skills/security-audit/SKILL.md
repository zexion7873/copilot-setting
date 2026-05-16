---
name: security-audit
description: 'Use when user needs an OWASP-focused security audit of Java web code — injection, auth, access control, and configuration review. Triggers on: security audit, OWASP, vulnerability check, security review, 資安審查, 安全檢查, 有沒有漏洞, 資安. Produces severity-classified security findings. Do NOT use for general code review (prefer code-review), SQL-only review (prefer sql-review), or performance review (prefer performance).'
---

# Security Audit — Workflow

OWASP Top 10 focused audit. Security rules: `instructions/security.instructions.md`.

Full coding rules in `instructions/*.instructions.md`. Key rules:

- **SQL**: `PreparedStatement` with `?` only — see `instructions/sql.instructions.md`
- **XSS**: `<c:out>` for all JSP output — see `instructions/jsp.instructions.md`
- **Auth**: session management, cookie flags — see `instructions/security.instructions.md`

## Phase 1 — Map Attack Surface

1. Identify entry points: servlets, controllers, API endpoints, file uploads
2. Identify data flows: user input → processing → storage → output
3. Identify trust boundaries: authenticated vs public, admin vs user

## Phase 2 — Check by OWASP Category

For each entry point, check against A01–A10 from `instructions/security.instructions.md`:
- A01: access control on every resource
- A03: injection (SQL, OS, XSS) at every input
- A07: session management and cookie flags
- A05: error handling leaks, default credentials
- A10: SSRF on any URL fetch

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
