---
name: security-audit
description: 'Systematic security audit workflow based on OWASP Top 10 for Java web applications. Use when user asks for a security review, vulnerability assessment, or mentions "/security-audit". Walks through: attack surface mapping, OWASP category-by-category analysis, Java 8 specific vulnerability checks, severity classification, remediation planning, and verification. Designed for @security agent but usable by any agent performing security review.'
license: MIT
allowed-tools: ['search', 'read/problems']
---

# Security Audit — Executable Workflow

## Overview

A structured security audit process that replaces ad-hoc "look for bad code" with systematic attack surface mapping and category-by-category vulnerability analysis. This skill defines HOW to audit, not WHAT the rules are (those live in the agent prompt and `security-and-owasp.instructions.md`).

## When to Use

- User asks for a security review or vulnerability assessment
- Pre-release security check before deploying to production
- Reviewing code that handles authentication, file I/O, or external input
- User mentions `/security-audit`, "OWASP check", or "is this secure"

---

## Phase 1 — Map the Attack Surface

Before checking any vulnerability category, build an inventory of what can be attacked.

### 1.1 Identify Entry Points

```bash
# Find HTTP servlet endpoints
grep -rn "doGet\|doPost\|doPut\|doDelete\|service(" --include="*.java" src/

# Find filter and listener registrations
grep -rn "implements Filter\|implements ServletContextListener" --include="*.java" src/

# Find file upload handling
grep -rn "getPart\|getInputStream\|MultipartFile\|multipart" --include="*.java" src/

# Find scheduled tasks (background entry points)
grep -rn "@Scheduled\|Timer\|ScheduledExecutorService\|TimerTask" --include="*.java" src/

# Find REST/API annotations (if using JAX-RS)
grep -rn "@Path\|@GET\|@POST\|@PUT\|@DELETE" --include="*.java" src/
```

### 1.2 Identify Data Flows

Trace user input from entry to storage to output:

```
Entry points:
  HttpServletRequest.getParameter()
  HttpServletRequest.getHeader()
  HttpServletRequest.getInputStream()
  request.getPart() / getParts()

Processing:
  Business logic, validation, transformation

Storage:
  JDBC / PreparedStatement / Statement
  File system writes
  Session attributes

Output:
  HttpServletResponse.getWriter()
  JSON serialization
  Log statements
```

### 1.3 Identify Trust Boundaries

```bash
# Find authentication checks
grep -rn "getSession\|isAuthenticated\|getUserPrincipal\|getRemoteUser" --include="*.java" src/

# Find role/permission checks
grep -rn "isUserInRole\|hasRole\|hasPermission\|checkAccess" --include="*.java" src/

# Find public vs protected paths
grep -rn "web.xml\|security-constraint\|auth-constraint" --include="*.xml" .
```

### 1.4 Identify Sensitive Data

```bash
# Find PII and credential handling
grep -rn "password\|passwd\|secret\|apiKey\|token\|ssn\|creditCard\|email" --include="*.java" src/

# Find data written to logs
grep -rn "log\.\(info\|debug\|warn\|error\)" --include="*.java" src/ | grep -i "password\|token\|secret"
```

### 1.5 Attack Surface Inventory

Document findings in this table before proceeding:

```
| Entry Point       | Input Type     | Auth Required | Sensitive Data | Trust Level |
|-------------------|---------------|---------------|----------------|-------------|
| /login (POST)     | Form params   | No            | Password       | Public      |
| /api/user/{id}    | Path param    | Yes           | PII            | Authenticated |
| /upload           | Multipart     | Yes           | File content   | Authenticated |
| ScheduledJob      | DB / config   | N/A           | None           | Internal    |
```

---

## Phase 2 — OWASP Top 10 Systematic Check

Work through each category in order. Do not skip categories even if they seem unlikely.

### A01: Broken Access Control

**What to search for:**

```bash
# Find endpoints missing authorization checks
grep -rn "doGet\|doPost" --include="*.java" src/ -A 20 | grep -v "getSession\|isUserInRole\|checkAccess"

# Find direct object references using user-supplied IDs
grep -rn "getParameter.*[Ii]d\|getParameter.*[Uu]ser" --include="*.java" src/

# Find path traversal risks
grep -rn "new File.*getParameter\|Paths.get.*getParameter" --include="*.java" src/

# Find CORS configuration
grep -rn "Access-Control-Allow-Origin\|CorsFilter\|cors" --include="*.java" --include="*.xml" src/
```

**Bad vs Good:**

```java
// BAD: No authorization check — any authenticated user can access any record
protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
    String userId = req.getParameter("userId");
    User user = userDao.findById(userId);  // IDOR — attacker changes userId
    writeJson(resp, user);
}

// GOOD: Verify the requester owns the resource
protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
    String requestedId = req.getParameter("userId");
    String sessionUserId = (String) req.getSession().getAttribute("userId");
    if (!sessionUserId.equals(requestedId) && !isAdmin(req)) {
        resp.sendError(HttpServletResponse.SC_FORBIDDEN);
        return;
    }
    User user = userDao.findById(requestedId);
    writeJson(resp, user);
}
```

**Path traversal fix:**

```java
// BAD
File file = new File(BASE_DIR + req.getParameter("filename"));

// GOOD: Canonicalize and verify the path stays within the base directory
File requested = new File(BASE_DIR, req.getParameter("filename")).getCanonicalFile();
if (!requested.getPath().startsWith(new File(BASE_DIR).getCanonicalPath())) {
    resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid path");
    return;
}
```

---

### A02: Cryptographic Failures

**What to search for:**

```bash
# Find hardcoded secrets
grep -rn "password\s*=\s*\"[^\"]\+\"\|apiKey\s*=\s*\"[^\"]\+\"\|secret\s*=\s*\"[^\"]\+\"" --include="*.java" src/

# Find weak hashing
grep -rn "MessageDigest.getInstance.*MD5\|MessageDigest.getInstance.*SHA-1\|MessageDigest.getInstance.*SHA1" --include="*.java" src/

# Find sensitive data in logs
grep -rn "log\.\(info\|debug\|warn\|error\).*password\|log\.\(info\|debug\|warn\|error\).*token" --include="*.java" src/

# Find HTTP (non-HTTPS) URLs hardcoded
grep -rn "\"http://" --include="*.java" --include="*.properties" --include="*.xml" src/
```

**Bad vs Good:**

```java
// BAD: Hardcoded secret
private static final String DB_PASSWORD = "admin123";

// GOOD: Load from environment
private static final String DB_PASSWORD = System.getenv("DB_PASSWORD");

// BAD: MD5 for password hashing
MessageDigest md = MessageDigest.getInstance("MD5");
byte[] hash = md.digest(password.getBytes());

// GOOD: Use BCrypt (add bcrypt dependency to pom.xml)
import org.mindrot.jbcrypt.BCrypt;
String hashed = BCrypt.hashpw(password, BCrypt.gensalt(12));
boolean valid = BCrypt.checkpw(candidate, hashed);

// BAD: Logging sensitive data
log.info("User login attempt: username={}, password={}", username, password);

// GOOD: Never log credentials
log.info("User login attempt: username={}", username);
```

---

### A03: Injection

**What to search for:**

```bash
# Find SQL injection via string concatenation
grep -rn "\"SELECT\|\"INSERT\|\"UPDATE\|\"DELETE" --include="*.java" src/ | grep "+"

# Find Statement (not PreparedStatement)
grep -rn "createStatement()\|Statement stmt\|Statement s " --include="*.java" src/

# Find command injection
grep -rn "Runtime.getRuntime().exec\|ProcessBuilder" --include="*.java" src/

# Find XSS risks (unescaped output)
grep -rn "getWriter().print\|getWriter().write\|getOutputStream().write" --include="*.java" src/ -A 3

# Find log injection
grep -rn "log\.\(info\|debug\|warn\|error\).*getParameter\|log\.\(info\|debug\|warn\|error\).*getHeader" --include="*.java" src/
```

**Bad vs Good:**

```java
// BAD: SQL injection via string concatenation
String query = "SELECT * FROM users WHERE username = '" + username + "'";
Statement stmt = conn.createStatement();
ResultSet rs = stmt.executeQuery(query);

// GOOD: Parameterized query
String query = "SELECT * FROM users WHERE username = ?";
PreparedStatement stmt = conn.prepareStatement(query);
stmt.setString(1, username);
ResultSet rs = stmt.executeQuery();

// BAD: Command injection
String cmd = "ping " + req.getParameter("host");
Runtime.getRuntime().exec(cmd);

// GOOD: Validate input strictly, use array form
String host = req.getParameter("host");
if (!host.matches("[a-zA-Z0-9.-]+")) {
    resp.sendError(HttpServletResponse.SC_BAD_REQUEST);
    return;
}
ProcessBuilder pb = new ProcessBuilder("ping", "-c", "1", host);

// BAD: Log injection (attacker injects newlines to forge log entries)
log.info("User action: {}", req.getParameter("action"));

// GOOD: Sanitize before logging
String action = req.getParameter("action").replaceAll("[\r\n]", "_");
log.info("User action: {}", action);
```

---

### A04: Insecure Design

**What to search for:**

```bash
# Find login endpoints without rate limiting
grep -rn "doPost" --include="*.java" src/ -A 30 | grep -i "login\|authenticate\|password"

# Find missing input validation
grep -rn "getParameter" --include="*.java" src/ | grep -v "isEmpty\|isBlank\|matches\|validate\|length"

# Find account lockout logic (absence is the finding)
grep -rn "failedAttempts\|lockout\|loginAttempt" --include="*.java" src/
```

**Patterns to implement:**

```java
// Rate limiting — track attempts per IP in a ConcurrentHashMap
private static final Map<String, AtomicInteger> loginAttempts = new ConcurrentHashMap<>();
private static final int MAX_ATTEMPTS = 5;

// Account lockout check before processing credentials
AtomicInteger attempts = loginAttempts.computeIfAbsent(clientIp, k -> new AtomicInteger(0));
if (attempts.get() >= MAX_ATTEMPTS) {
    resp.sendError(429, "Too many login attempts. Try again later.");
    return;
}

// Input validation before use
String username = req.getParameter("username");
if (username == null || username.isBlank() || username.length() > 50
        || !username.matches("[a-zA-Z0-9_@.-]+")) {
    resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid username format");
    return;
}
```

---

### A05: Security Misconfiguration

**What to search for:**

```bash
# Find debug mode flags
grep -rn "debug\s*=\s*true\|DEBUG\s*=\s*true\|devMode\s*=\s*true" --include="*.properties" --include="*.xml" .

# Find default or hardcoded credentials
grep -rn "admin.*admin\|root.*root\|password.*password\|changeme" --include="*.properties" --include="*.xml" .

# Find verbose error output to client
grep -rn "e.printStackTrace\|getWriter.*getMessage\|getWriter.*getStackTrace" --include="*.java" src/

# Find missing security headers
grep -rn "setHeader\|addHeader" --include="*.java" src/ | grep -i "X-Frame\|Content-Security\|X-Content-Type\|Strict-Transport"
```

**Security headers to add:**

```java
// Add in a Filter applied to all responses
resp.setHeader("X-Content-Type-Options", "nosniff");
resp.setHeader("X-Frame-Options", "DENY");
resp.setHeader("X-XSS-Protection", "1; mode=block");
resp.setHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
resp.setHeader("Content-Security-Policy", "default-src 'self'");
resp.setHeader("Cache-Control", "no-store");

// BAD: Leaking stack traces to client
} catch (Exception e) {
    e.printStackTrace();
    resp.getWriter().write(e.getMessage());
}

// GOOD: Log internally, return generic error
} catch (Exception e) {
    log.error("Unexpected error processing request", e);
    resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "An error occurred");
}
```

---

### A07: Authentication Failures

**What to search for:**

```bash
# Find session creation without invalidating old session (session fixation)
grep -rn "getSession(true)\|getSession()" --include="*.java" src/ -B 5 | grep -v "invalidate"

# Find session timeout configuration
grep -rn "session-timeout\|setMaxInactiveInterval" --include="*.java" --include="*.xml" .

# Find "remember me" token storage
grep -rn "rememberMe\|remember_me\|persistent.*token\|cookie.*token" --include="*.java" src/
```

**Session fixation fix:**

```java
// BAD: Reuses existing session — attacker can fixate session ID
HttpSession session = req.getSession(true);
session.setAttribute("userId", userId);

// GOOD: Invalidate old session, create new one after login
HttpSession oldSession = req.getSession(false);
if (oldSession != null) {
    oldSession.invalidate();
}
HttpSession newSession = req.getSession(true);
newSession.setAttribute("userId", userId);
newSession.setMaxInactiveInterval(1800); // 30 minutes
```

**Cookie security:**

```java
// BAD: Cookie without security flags
Cookie sessionCookie = new Cookie("JSESSIONID", sessionId);
resp.addCookie(sessionCookie);

// GOOD: All security flags set
Cookie sessionCookie = new Cookie("JSESSIONID", sessionId);
sessionCookie.setHttpOnly(true);
sessionCookie.setSecure(true);
sessionCookie.setPath("/");
sessionCookie.setMaxAge(1800);
// SameSite requires header manipulation in Java 8 (no direct API)
resp.addHeader("Set-Cookie",
    "JSESSIONID=" + sessionId + "; HttpOnly; Secure; SameSite=Strict; Path=/; Max-Age=1800");
```

---

### A08: Data Integrity Failures

**What to search for:**

```bash
# Find ObjectInputStream usage (unsafe deserialization)
grep -rn "ObjectInputStream\|readObject()\|deserialize" --include="*.java" src/

# Find XML parsing without XXE protection
grep -rn "DocumentBuilderFactory\|SAXParserFactory\|XMLInputFactory" --include="*.java" src/

# Find integrity checks on critical operations
grep -rn "transfer\|payment\|delete.*all\|truncate" --include="*.java" src/ | grep -v "checksum\|verify\|confirm"
```

**Unsafe deserialization fix:**

```java
// BAD: Deserializing untrusted data
ObjectInputStream ois = new ObjectInputStream(req.getInputStream());
Object obj = ois.readObject();  // Remote code execution risk

// GOOD: Use JSON instead of Java serialization for external data
// If Java serialization is unavoidable, use a filter:
ObjectInputStream ois = new ObjectInputStream(req.getInputStream()) {
    @Override
    protected Class<?> resolveClass(ObjectStreamClass desc) throws IOException, ClassNotFoundException {
        if (!ALLOWED_CLASSES.contains(desc.getName())) {
            throw new InvalidClassException("Unauthorized deserialization: " + desc.getName());
        }
        return super.resolveClass(desc);
    }
};
```

**XXE prevention:**

```java
// BAD: Default XML parser allows external entities
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
DocumentBuilder db = dbf.newDocumentBuilder();
Document doc = db.parse(req.getInputStream());

// GOOD: Disable external entities
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
dbf.setExpandEntityReferences(false);
DocumentBuilder db = dbf.newDocumentBuilder();
Document doc = db.parse(req.getInputStream());
```

---

## Phase 3 — Java 8 Specific Checks

These checks apply regardless of OWASP category.

### 3.1 PreparedStatement Audit

```bash
# Find all Statement usage (should be zero in production code)
grep -rn "conn\.createStatement\(\)\|Statement [a-z]" --include="*.java" src/

# Verify all queries use parameterized form
grep -rn "prepareStatement" --include="*.java" src/ -A 5 | grep "setString\|setInt\|setLong\|setDate"
```

### 3.2 SecureRandom vs Random

```bash
# Find insecure Random usage for security-sensitive operations
grep -rn "new Random()\|Math.random()" --include="*.java" src/ -B 3 | grep -i "token\|session\|key\|secret\|nonce"
```

```java
// BAD: Predictable random for security tokens
String token = Long.toHexString(new Random().nextLong());

// GOOD: Cryptographically secure
SecureRandom sr = new SecureRandom();
byte[] tokenBytes = new byte[32];
sr.nextBytes(tokenBytes);
String token = Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes);
```

### 3.3 Resource Cleanup

```bash
# Find connections not closed in finally or try-with-resources
grep -rn "getConnection()\|prepareStatement\|createStatement" --include="*.java" src/ -A 20 | grep -v "try\s*(" | grep -v "finally"
```

```java
// BAD: Connection leak if exception occurs
Connection conn = dataSource.getConnection();
PreparedStatement stmt = conn.prepareStatement(sql);
ResultSet rs = stmt.executeQuery();
// ... if exception here, conn is never closed

// GOOD: try-with-resources guarantees cleanup
try (Connection conn = dataSource.getConnection();
     PreparedStatement stmt = conn.prepareStatement(sql);
     ResultSet rs = stmt.executeQuery()) {
    // process results
}
```

### 3.4 Thread Safety of Shared State

```bash
# Find static mutable fields (potential race conditions)
grep -rn "private static [^f].*=\|static [^f].*Map\|static [^f].*List" --include="*.java" src/

# Find servlet instance variables (servlets are singletons)
grep -rn "class.*extends HttpServlet" --include="*.java" src/ -A 20 | grep "private [^s]"
```

---

## Phase 4 — Classify Findings

### Severity Definitions

```
🔴 CRITICAL — Exploitable vulnerability, immediate risk
  Examples: SQL injection, RCE via deserialization, auth bypass, hardcoded credentials

🟠 HIGH — Significant vulnerability, requires prompt fix
  Examples: XSS, session fixation, missing auth on sensitive endpoint, XXE

🟡 MEDIUM — Potential vulnerability, should fix in current sprint
  Examples: Missing rate limiting, weak hashing, verbose error messages, missing security headers

🔵 LOW — Minor issue, fix when convenient
  Examples: Missing HttpOnly on non-session cookie, log injection with low impact, informational disclosure
```

### Issue Format

```
[SEVERITY] OWASP Category — Brief title
  Location: File#method (line N)
  Vulnerability: What's wrong and why it's dangerous
  Attack Scenario: Step-by-step how an attacker exploits this
  Remediation: How to fix (with before/after code if applicable)
  Verification: How to confirm the fix works
```

**Example:**

```
🔴 CRITICAL — A03: Injection — SQL Injection in user search
  Location: UserServlet#doGet (line 47)
  Vulnerability: Username parameter concatenated directly into SQL query.
  Attack Scenario: Attacker sends username=' OR '1'='1 to bypass authentication,
    or username='; DROP TABLE users;-- to destroy data.
  Remediation: Replace Statement with PreparedStatement using ? placeholders.
  Verification: Send username=' OR '1'='1 — query should return no results or throw
    a validation error, not return all users.
```

---

## Phase 5 — Remediation Plan

### 5.1 Priority Ordering

Fix in this order:

1. **CRITICAL** — Stop everything. Fix before any other work.
2. **HIGH** — Fix in the current sprint, before next release.
3. **MEDIUM** — Schedule in the next sprint.
4. **LOW** — Add to backlog, fix opportunistically.

### 5.2 Quick Wins vs Structural Changes

| Type | Examples | Effort |
|------|---------|--------|
| Quick win | Add security headers in a Filter, set cookie flags, remove debug logging | Hours |
| Moderate | Replace Statement with PreparedStatement, add input validation | Days |
| Structural | Add rate limiting infrastructure, redesign auth flow, replace serialization | Weeks |

### 5.3 Dependency Updates

```bash
# Check for known vulnerable dependencies
mvn dependency:tree | grep -E "commons-collections|log4j|jackson-databind|xstream"

# Run OWASP dependency check plugin
mvn org.owasp:dependency-check-maven:check
```

### 5.4 Configuration Changes

```bash
# Verify no debug flags in production config
grep -rn "debug\|verbose\|stacktrace" src/main/resources/ --include="*.properties"

# Verify HTTPS enforcement in web.xml
grep -A5 "transport-guarantee" src/main/webapp/WEB-INF/web.xml
```

---

## Phase 6 — Verification

### 6.1 Verify Each Fix

For every remediated finding:

```
□ The vulnerable code pattern no longer exists (grep confirms)
□ The fix compiles and tests pass (mvn test)
□ The attack scenario from the finding no longer works
□ No regression in adjacent functionality
```

### 6.2 Negative Testing Patterns

Test that security controls actually block attacks:

```
SQL Injection:
  Input: ' OR '1'='1
  Input: '; DROP TABLE users;--
  Expected: Error or empty result, NOT data from other users

Path Traversal:
  Input: ../../etc/passwd
  Input: ..%2F..%2Fetc%2Fpasswd
  Expected: 400 Bad Request, NOT file contents

XSS:
  Input: <script>alert(1)</script>
  Expected: Escaped output in HTML, NOT script execution

Auth Bypass:
  Action: Access /api/user/999 as user with ID 1
  Expected: 403 Forbidden, NOT user 999's data
```

### 6.3 Regression Testing

```bash
# Run full test suite after each fix
mvn test

# Run specific security-related tests
mvn test -Dtest=*SecurityTest,*AuthTest,*ValidationTest

# Verify no new compiler warnings introduced
mvn compile 2>&1 | grep -i "warning\|deprecated"
```

---

## Security Audit Anti-Patterns

| Anti-Pattern | Why It Fails | Do This Instead |
|-------------|-------------|-----------------|
| Checklist-only review | Misses context-specific vulnerabilities | Map the attack surface first |
| Fixing symptoms not root cause | Vulnerability reappears in a different form | Trace data flow end-to-end |
| Security through obscurity | Assumes attacker doesn't have source code | Assume attacker has full source access |
| Ignoring low-severity findings | Low findings chain into critical exploits | Document all findings, fix by priority |
| Auditing only "security code" | Vulnerabilities hide in business logic | Review all code that touches user input |
| Skipping negative tests | Fix looks correct but doesn't block attacks | Always test that the attack fails after fix |
