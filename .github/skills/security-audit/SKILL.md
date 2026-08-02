---
name: security-audit
description: 'Use when user needs an OWASP-focused security audit of web application code — injection, auth, access control, and configuration review. Triggers on: security audit, OWASP, vulnerability check, 資安審查, 有沒有漏洞. Produces severity-classified security findings. Do NOT use for general code review (prefer code-review) or SQL-only review (prefer sql-review).'
---

# Security Audit — Workflow

OWASP Top 10 focused audit. Canonical rules: the stack's security module under `instructions/`.

## Phase 0 — Load canonical rules

**MANDATORY pre-load gate — do NOT report findings (Phase 4) until you have opened the stack instruction modules for the code under audit.** Your training data defaults to the newest idioms; the files under `instructions/` are this project's stack modules — its version lock and house rules. At minimum open the security, SQL/query, and view/template modules; add any other module covering the layers under audit. The negative lists in the agent body are a floor, not the full rules.

Read-back receipt (self-check, not machine-enforced): before leaving this step, NAME each module you opened and QUOTE the single most load-bearing rule from each that applies to this audit — a generic restatement you could have written from memory means you skipped the file, so open it for real.

## Phase 1 — Map Attack Surface

1. Identify entry points: controllers, request handlers, API endpoints, file uploads
2. Identify data flows: user input → processing → storage → output
3. Identify trust boundaries: authenticated vs public, admin vs user

## Phase 2 — Check by OWASP Category

For each entry point, trace data flow from input → processing → storage → output and check:

**A01 Broken Access Control** (check each):
- [ ] Every endpoint enforces role/permission — not just login check
- [ ] Object references (ID in URL/param) validated against current user's ownership (IDOR)
- [ ] No path traversal: file paths from user input sanitized
- [ ] HTTP method restrictions enforced (mutations via POST/PUT/DELETE only — never GET; route declarations restrict the method explicitly)
- [ ] CSRF: all state-changing POST forms carry a CSRF token (framework CSRF protection or manual token+session check, per the security module)

**A02 Cryptographic Failures** (check each):
- [ ] Passwords hashed with bcrypt or Argon2 per the security module's A02 rules — never plaintext, MD5, or SHA1
- [ ] Sensitive data encrypted at rest and in transit
- [ ] No secrets in logs, error messages, or client responses
- [ ] No hardcoded credentials in source or config — search for password/secret/apikey/token literals

**A03 Injection** (check each):
- [ ] SQL/ORM queries: all parameterized via positional or named binds — search for string concatenation near the stack's query-construction APIs
- [ ] OS command: no shell-string execution (single-string exec or `sh -c` style); user input passed only as discrete argument-list elements
- [ ] XSS: every template/view output context-aware encoded — search for raw interpolation in views
- [ ] XXE: every XML parser of user-supplied input disables DTDs / external entities per the security module (each parser API has its own switch) — search for XML parser construction on request data

**A04 Insecure Design** (check each):
- [ ] Rate limiting on login/registration/password-reset
- [ ] Business logic validation not bypassable by skipping steps

**A05 Security Misconfiguration** (check each):
- [ ] Error responses don't leak stack traces or internal paths
- [ ] No default credentials or debug endpoints in production config

**A06 Vulnerable Components** (check each):
- [ ] Key dependencies not on known-CVE versions
- [ ] Require the author to attach a fresh dependency-vulnerability scan report (the scanner named in the stack's security module) — the reviewer is read-only and cannot run the build (mirrors `code-review` Phase 4 build-evidence rule); cross-check flagged dependencies against CVE advisories. Do NOT accept a version-drift report as a CVE scan — drift is not vulnerability data
- [ ] EOL framework versions pinned by the declared stack — document known unpatched CVEs as baseline risk

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

Close with a one-line summary (mirrors `sql-review` — no free-form prose conclusion):

`Findings: N critical, N high, N medium, N low | Baseline risk: <EOL-stack CVE note per A06> | Top exposure: <one line>`

## Handoffs

- → `@implementer` — to fix security findings
