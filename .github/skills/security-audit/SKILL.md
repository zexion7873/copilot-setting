---
name: security-audit
description: 'Use when user asks for security review, vulnerability scan, penetration test preparation, or OWASP assessment. Triggers on: security audit, security review, vulnerability scan, penetration test, OWASP Top 10, OWASP assessment, security check, 資安審查, 有沒有漏洞, 安全性檢查, 弱點掃描, 安全審查, 資安評估. Targets Java web applications with OWASP Top 10 analysis and severity classification. Do NOT use for general code review without security focus — prefer code-review skill instead.'
---

# Security Audit — Workflow

Systematic Java web app security audit.

Full coding standards live in `instructions/*.instructions.md` (auto-applied when matching files are open). When working via agent chat, these non-negotiable rules still apply:

- **SQL**: `PreparedStatement` with `?` only — string concatenation is always CRITICAL (A03 Injection)
- **Exceptions**: no empty `catch` blocks; no stack trace exposure to clients; no `e.getMessage()` in HTTP responses
- **Logging**: never log secrets, tokens, PII, or session IDs; SLF4J parameterized only
- **Resources**: `try-with-resources` for all `AutoCloseable` — unclosed resources are a misconfiguration finding (A05)
- **Security**: no hardcoded secrets; `<c:out>` for all dynamic output in JSP; validate inputs at boundaries; cookies must be `HttpOnly` + `Secure` + `SameSite=Strict`

## Phase 1 — Map the Attack Surface

Inventory entry points before checking any vulnerability category: HTTP entry points (Servlets, Filters, JAX-RS), input surfaces (file upload, streams), auth boundaries, and sensitive data locations.

Record as: `| Entry Point | Input Type | Auth Required | Sensitive Data | Trust Level |`

## Phase 2 — OWASP Top 10 Sweep

Work each category in order. Do not skip.

- **A01 Broken Access Control** — IDOR candidates (user-supplied IDs), path traversal
- **A02 Cryptographic Failures** — hardcoded secrets, weak hashing (MD5/SHA-1), `Math.random()` for security
- **A03 Injection** — SQL concatenation, non-prepared statements, shell injection, XSS surfaces
- **A04 Insecure Design** — missing rate limiting, missing lockout, shared mutable servlet state
- **A05 Security Misconfiguration** — debug enabled, default credentials, stack trace exposure, resource leaks
- **A07 Authentication Failures** — session fixation, missing HttpOnly/Secure on cookies
- **A08 Data Integrity** — unsafe deserialization, XXE candidates

## Phase 3 — Classify Findings

- **CRITICAL** — exploitable now: SQLi, RCE, auth bypass, hardcoded creds
- **HIGH** — fix this sprint: XSS, session fixation, missing auth on sensitive endpoint
- **MEDIUM** — next sprint: weak hashing, missing rate limiting, verbose errors
- **LOW** — opportunistic: info disclosure, low-impact log injection

Finding format:

```
[SEVERITY] OWASP <category> — Title
  Location: File#method:line
  Vulnerability: <what + why dangerous>
  Remediation: <specific fix>
```

## Phase 4 — Remediation Plan

Fix order: CRITICAL → HIGH → MEDIUM → LOW.

| Bucket | Examples | Effort |
|---|---|---|
| Quick win | Security headers, cookie flags, remove debug logging | Hours |
| Moderate | Statement → PreparedStatement, add input validation | Days |
| Structural | Rate limiting infra, auth redesign, replace serialization | Weeks |

## Phase 5 — Verify Fixes

For every remediated finding: confirm vulnerable pattern is gone, tests pass, and the original attack scenario now fails.
