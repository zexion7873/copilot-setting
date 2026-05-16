---
name: security-audit
description: 'Use when user needs an OWASP-focused security audit of Java web code — injection, auth, access control, and configuration review. Triggers on: security audit, OWASP, vulnerability check, security review, 資安審查, 安全檢查, 有沒有漏洞, 資安. Produces severity-classified security findings. Do NOT use for general code review (prefer code-review), SQL-only review (prefer sql-review), or performance review (prefer performance).'
---

# Security Audit — Workflow

OWASP Top 10 focused audit. Rules: `instructions/security.instructions.md`.

Full coding rules in `instructions/*.instructions.md`. Key rules:

- **SQL**: `PreparedStatement` with `?` only — see `instructions/sql.instructions.md`
- **XSS**: `<c:out>` for all JSP output — see `instructions/jsp.instructions.md`
- **Auth**: session management, cookie flags — see `instructions/security.instructions.md`

## Attack Surface

Identify: entry points (servlets, controllers, APIs, file uploads), data flows (input → processing → storage → output), trust boundaries (auth vs public, admin vs user).

## OWASP Checklist

Check each entry point against `instructions/security.instructions.md`:

- **A01** Access Control: rights checked per resource?
- **A02** Crypto: passwords hashed? secrets externalized?
- **A03** Injection: SQL parameterized? OS commands escaped? XSS encoded?
- **A04** Insecure Design: rate limiting? server-side validation?
- **A05** Misconfiguration: error pages generic? headers set?
- **A06** Vulnerable Components: dependencies pinned? CVEs checked?
- **A07** Auth Failures: new session on login? cookie flags set?
- **A08** Integrity: no untrusted deserialization?
- **A09** Logging Failures: auth events logged? log input sanitized?
- **A10** SSRF: URL allow-list? private IPs blocked?

## Severity

| Level | Criteria |
|---|---|
| 🔴 CRITICAL | Exploitable now; data breach or RCE possible |
| 🟠 HIGH | Exploitable with moderate effort |
| 🟡 MEDIUM | Defense-in-depth gap; not directly exploitable |
| ⚪ LOW | Best practice deviation; minimal risk |

## Output

Per finding: `[SEVERITY] A0N — title @ file:line → issue → fix`

## Handoffs

- → `@implementer` — to fix security findings
- ← `@reviewer` — security mode activated
- ← `code-review` skill — code review finds security concerns
