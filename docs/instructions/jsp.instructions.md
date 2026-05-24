---
description: 'JSP template conventions — XSS prevention, JSTL-only policy, and output encoding.'
applyTo: '**/*.jsp'
# Author reference only. Runtime rules are embedded in agents/*.agent.md (Coding Standards section).
---

# JSP Conventions

XSS prevention is the #1 priority. All dynamic output must be encoded.

## Output Encoding

- **Every** dynamic value: `<c:out value="${...}"/>` or `fn:escapeXml()` — no raw `${...}` in HTML
- JavaScript context: JSON-encode server-side before embedding in `<script>`
- URL context: `<c:url>` with `<c:param>` for proper encoding

## JSTL Only

- No scriptlets (`<% ... %>`) — ever
- No expression tags (`<%= ... %>`) — use `<c:out>`
- Logic: `<c:if>`, `<c:choose>`, `<c:forEach>`
- Formatting: `<fmt:formatDate>`, `<fmt:formatNumber>`

## Includes

- `<jsp:include>` for dynamic; `<%@ include %>` for static
- Never include user-supplied paths

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `${user.name}` without encoding | XSS — attacker injects script | `<c:out value="${user.name}"/>` |
| `<%= request.getParameter("q") %>` | Scriptlet + unencoded = XSS | `<c:out value="${param.q}"/>` |
| `<% if (cond) { %>` | Scriptlet logic | `<c:if test="${cond}">` |
