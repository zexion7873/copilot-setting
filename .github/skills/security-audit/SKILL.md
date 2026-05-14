---
name: security-audit
description: 'Use when user asks for security review, vulnerability scan, penetration test preparation, or OWASP assessment. Triggers on: security audit, security review, vulnerability scan, penetration test, OWASP Top 10, OWASP assessment, security check, 資安審查, 有沒有漏洞, 安全性檢查, 弱點掃描, 安全審查, 資安評估. Targets Java web applications with OWASP Top 10 analysis and severity classification. Do NOT use for general code review without security focus — prefer code-review skill instead.'
---

# Security Audit — Workflow

Process for systematic Java web app security audit. Vulnerability rules live in `instructions/security-and-owasp.instructions.md`. This file defines the order of attack.

Full coding standards live in `instructions/` (auto-applied when matching files are open). When working via agent chat, these non-negotiable rules still apply:

- **SQL**: `PreparedStatement` with `?` only — string concatenation is always CRITICAL (A03 Injection)
- **Exceptions**: no empty `catch` blocks; no stack trace exposure to clients; no `e.getMessage()` in HTTP responses
- **Logging**: never log secrets, tokens, PII, or session IDs; SLF4J parameterized only
- **Resources**: `try-with-resources` for all `AutoCloseable` — unclosed resources are a misconfiguration finding (A05)
- **Security**: no hardcoded secrets; `<c:out>` for all dynamic output in JSP; validate inputs at boundaries; cookies must be `HttpOnly` + `Secure` + `SameSite=Strict`

## Phase 1 — Map the Attack Surface

Inventory entry points before checking any vulnerability category.

```bash
# HTTP entry points
grep -rn "doGet\|doPost\|doPut\|doDelete\|service(" --include="*.java" src/
grep -rn "implements Filter\|implements ServletContextListener" --include="*.java" src/
grep -rn "@Path\|@GET\|@POST\|@PUT\|@DELETE" --include="*.java" src/

# Input surfaces
grep -rn "getPart\|getInputStream\|MultipartFile" --include="*.java" src/

# Auth boundaries
grep -rn "getSession\|isAuthenticated\|getUserPrincipal\|isUserInRole\|hasRole" --include="*.java" src/

# Sensitive data
grep -rn "password\|passwd\|secret\|apiKey\|token\|ssn\|creditCard" --include="*.java" src/
```

Record as a table: `| Entry Point | Input Type | Auth Required | Sensitive Data | Trust Level |`.

## Phase 2 — OWASP Top 10 Sweep

Work each category in order. Do not skip.

### A01 — Broken Access Control

```bash
grep -rn "getParameter.*[Ii]d" --include="*.java" src/                              # IDOR candidates
grep -rn "new File.*getParameter\|Paths.get.*getParameter" --include="*.java" src/  # path traversal
```

### A02 — Cryptographic Failures

```bash
grep -rn 'password\s*=\s*"[^"]\+"\|apiKey\s*=\s*"[^"]\+"\|secret\s*=\s*"[^"]\+"' --include="*.java" src/
grep -rn "MessageDigest.getInstance.*\(MD5\|SHA-1\|SHA1\)" --include="*.java" src/  # weak hash
grep -rn "new Random()\|Math.random()" --include="*.java" src/ -B 3 | grep -i "token\|session\|key\|nonce"  # use SecureRandom
```

### A03 — Injection

```bash
grep -rn '"SELECT\|"INSERT\|"UPDATE\|"DELETE' --include="*.java" src/ | grep "+"   # SQL concat
grep -rn "createStatement()\|Statement [a-z]" --include="*.java" src/              # non-prepared
grep -rn "Runtime.getRuntime().exec\|ProcessBuilder" --include="*.java" src/       # shell injection
grep -rn "getWriter().print\|getWriter().write" --include="*.java" src/            # XSS surfaces
```

### A04 — Insecure Design

```bash
grep -rn "failedAttempts\|lockout\|loginAttempt" --include="*.java" src/     # absence is the finding
grep -rn "class.*extends HttpServlet" --include="*.java" src/ -A 20 | grep "private [^s]"  # singleton instance fields = shared mutable state
```

### A05 — Security Misconfiguration

```bash
grep -rn "debug\s*=\s*true\|admin.*admin\|root.*root\|changeme" --include="*.properties" --include="*.xml" .
grep -rn "e.printStackTrace\|getWriter.*getMessage" --include="*.java" src/                # leaking traces
grep -rn "getConnection()" --include="*.java" src/ -A 20 | grep -v "try\s*("              # resource leak
```

### A07 — Authentication Failures

```bash
grep -rn "getSession(true)" --include="*.java" src/ -B 5 | grep -v "invalidate"  # session fixation
grep -rn "new Cookie" --include="*.java" src/ -A 5 | grep -v "setHttpOnly\|setSecure"
```

### A08 — Data Integrity Failures

```bash
grep -rn "ObjectInputStream\|readObject()" --include="*.java" src/        # unsafe deserialization
grep -rn "DocumentBuilderFactory\|SAXParserFactory\|XMLInputFactory" --include="*.java" src/  # XXE candidates
```

## Phase 3 — Classify Findings

Severity: **CRITICAL** (exploitable now — SQLi, RCE, auth bypass, hardcoded creds) → **HIGH** (fix this sprint — XSS, session fixation, missing auth on sensitive endpoint, XXE) → **MEDIUM** (next sprint — weak hashing, missing rate limiting, verbose errors, missing security headers) → **LOW** (opportunistic — info disclosure, low-impact log injection). Full category criteria in `instructions/security-and-owasp.instructions.md`.

Finding format:

```
[SEVERITY] OWASP <category> — Title
  Location: File#method:line
  Vulnerability: <what + why dangerous>
  Attack Scenario: <step-by-step exploit>
  Remediation: <specific fix>
  Verification: <how to confirm fix works>
```

## Phase 4 — Remediation Plan

Fix order: CRITICAL → HIGH → MEDIUM → LOW. Do not interleave categories.

Effort buckets:

| Bucket | Examples | Effort |
|---|---|---|
| Quick win | Security headers, cookie flags, remove debug logging | Hours |
| Moderate | Statement → PreparedStatement, add input validation | Days |
| Structural | Rate limiting infra, auth redesign, replace serialization | Weeks |

Dependency scan:

```bash
mvn dependency:tree | grep -E "commons-collections|log4j|jackson-databind|xstream"
mvn org.owasp:dependency-check-maven:check
```

## Phase 5 — Verify Fixes

For every remediated finding:

- Confirm vulnerable pattern is gone (re-run the original grep)
- Tests pass (`mvn test`)
- Negative test: the original attack scenario now fails
- No regression in adjacent functionality

Standard negative-test inputs:

```
SQL injection:    ' OR '1'='1   |   '; DROP TABLE users;--
Path traversal:   ../../etc/passwd   |   ..%2F..%2Fetc%2Fpasswd
XSS:              <script>alert(1)</script>
Auth bypass:      access /api/user/999 as user with ID 1
```

## Anti-Patterns

- Checklist-only review without attack-surface mapping → miss context-dependent vulns
- Fixing symptoms instead of tracing data flow → incomplete remediation
- Auditing only "security code" — vulns hide in business logic
- Skipping negative tests → can't confirm fix works
- Ignoring LOW findings → they chain into critical exploits
