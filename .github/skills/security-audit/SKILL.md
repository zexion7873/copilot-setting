---
name: security-audit
description: 'Use when user asks for security review, vulnerability scan, penetration test preparation, or OWASP assessment. Also triggers on: 資安審查, 有沒有漏洞, 安全性檢查, 弱點掃描. Targets Java web applications with OWASP Top 10 analysis and severity classification. Do NOT use for general code review without security focus — prefer code-review skill instead.'
---

# Security Audit — Workflow

Process for systematic Java web app security audit. Vulnerability rules live in `instructions/security-and-owasp.instructions.md`. This file defines the order of attack.

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

Work each category in order. Do not skip even if it seems unlikely.

### A01 — Broken Access Control

```bash
grep -rn "doGet\|doPost" --include="*.java" src/ -A 20 | grep -v "getSession\|isUserInRole\|checkAccess"
grep -rn "getParameter.*[Ii]d" --include="*.java" src/                    # IDOR candidates
grep -rn "new File.*getParameter\|Paths.get.*getParameter" --include="*.java" src/  # path traversal
grep -rn "Access-Control-Allow-Origin" --include="*.java" src/            # CORS misconfig
```

### A02 — Cryptographic Failures

```bash
grep -rn 'password\s*=\s*"[^"]\+"\|apiKey\s*=\s*"[^"]\+"\|secret\s*=\s*"[^"]\+"' --include="*.java" src/
grep -rn "MessageDigest.getInstance.*\(MD5\|SHA-1\|SHA1\)" --include="*.java" src/
grep -rn "log\.[a-z]\+.*\(password\|token\|secret\)" --include="*.java" src/
grep -rn '"http://' --include="*.java" --include="*.properties" --include="*.xml" src/
# Insecure Random for security-sensitive ops (use SecureRandom)
grep -rn "new Random()\|Math.random()" --include="*.java" src/ -B 3 | grep -i "token\|session\|key\|secret\|nonce"
```

### A03 — Injection

```bash
grep -rn '"SELECT\|"INSERT\|"UPDATE\|"DELETE' --include="*.java" src/ | grep "+"
grep -rn "createStatement()\|Statement [a-z]" --include="*.java" src/
grep -rn "Runtime.getRuntime().exec\|ProcessBuilder" --include="*.java" src/
grep -rn "getWriter().print\|getWriter().write" --include="*.java" src/   # XSS surfaces
grep -rn "log\.[a-z]\+.*getParameter\|log\.[a-z]\+.*getHeader" --include="*.java" src/  # log injection
```

### A04 — Insecure Design

```bash
grep -rn "doPost" --include="*.java" src/ -A 30 | grep -i "login\|authenticate"
grep -rn "failedAttempts\|lockout\|loginAttempt" --include="*.java" src/  # absence is the finding
grep -rn "getParameter" --include="*.java" src/ | grep -v "isEmpty\|matches\|validate\|length"
# Servlet instance variables — servlets are singletons, instance fields = shared mutable state
grep -rn "class.*extends HttpServlet" --include="*.java" src/ -A 20 | grep "private [^s]"
```

### A05 — Security Misconfiguration

```bash
grep -rn "debug\s*=\s*true\|DEBUG\s*=\s*true" --include="*.properties" --include="*.xml" .
grep -rn "admin.*admin\|root.*root\|changeme" --include="*.properties" --include="*.xml" .
grep -rn "e.printStackTrace\|getWriter.*getMessage" --include="*.java" src/   # leaking traces
grep -rn "setHeader\|addHeader" --include="*.java" src/ | grep -i "X-Frame\|Content-Security\|Strict-Transport"  # absence is the finding
# Resource leaks (Connection without try-with-resources)
grep -rn "getConnection()" --include="*.java" src/ -A 20 | grep -v "try\s*("
```

### A07 — Authentication Failures

```bash
grep -rn "getSession(true)" --include="*.java" src/ -B 5 | grep -v "invalidate"  # session fixation
grep -rn "session-timeout\|setMaxInactiveInterval" --include="*.java" --include="*.xml" .
grep -rn "new Cookie" --include="*.java" src/ -A 5 | grep -v "setHttpOnly\|setSecure"
```

### A08 — Data Integrity Failures

```bash
grep -rn "ObjectInputStream\|readObject()" --include="*.java" src/        # unsafe deserialization
grep -rn "DocumentBuilderFactory\|SAXParserFactory\|XMLInputFactory" --include="*.java" src/  # XXE candidates
```

## Phase 3 — Classify Findings

Severity:

```
CRITICAL — Exploitable vulnerability, immediate risk
  SQL injection, RCE, auth bypass, hardcoded credentials

HIGH — Significant vulnerability, fix this sprint
  XSS, session fixation, missing auth on sensitive endpoint, XXE

MEDIUM — Potential vulnerability, fix in next sprint
  Missing rate limiting, weak hashing, verbose errors, missing security headers

LOW — Minor issue, opportunistic fix
  Missing HttpOnly on non-session cookie, low-impact log injection, info disclosure
```

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

## Workflow Anti-Patterns

- Checklist-only review → map the attack surface first
- Fixing symptoms not root cause → trace data flow end-to-end
- Auditing only "security code" → vulnerabilities hide in business logic
- Skipping negative tests → fix may look correct but not block the attack
- Ignoring LOW findings → they chain into critical exploits
