---
description: 'JSP template conventions — XSS prevention, JSTL-only policy, and output encoding.'
applyTo: '**/*.jsp'
---

# JSP Conventions

XSS prevention is the #1 priority. All dynamic output must be encoded.

## Output Encoding

- **Every** dynamic value: `<c:out value="${...}"/>` or `fn:escapeXml()` — no raw `${...}` in HTML
- JavaScript context: JSON-encode server-side with `<` escaped as `\u003c` — plain JSON encoding leaves `</script>` intact and the HTML parser ends the script block at the first `</script>` regardless of string context; or pass the JSON in an HTML-escaped `data-*` attribute and read it from JS
- URL context: `<c:url>` with `<c:param>` for proper encoding

## JSTL Only

- No scriptlets (`<% ... %>`) — ever
- No expression tags (`<%= ... %>`) — use `<c:out>`
- Logic: `<c:if>`, `<c:choose>`, `<c:forEach>`
- Formatting: `<fmt:formatDate>`, `<fmt:formatNumber>`

## Includes

- `<jsp:include>` for dynamic; `<%@ include %>` for static
- Never include user-supplied paths

## Data Preparation

- JSP must NOT trigger lazy loading — all data must be fully prepared in the controller/service layer before forwarding to the view (Lazy Loading strategies: `instructions/spring-hibernate.instructions.md`)
- If a JSP accesses a Hibernate lazy collection, it means the service layer did not eagerly fetch the required data — fix the service, not the JSP

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `${user.name}` without encoding | XSS — attacker injects script | `<c:out value="${user.name}"/>` |
| `<%= request.getParameter("q") %>` | Scriptlet + unencoded = XSS | `<c:out value="${param.q}"/>` |
| `<% if (cond) { %>` | Untestable Java in the view; violates JSTL-only policy | `<c:if test="${cond}">` |
