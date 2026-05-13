---
description: 'JSP template conventions — output encoding, JSTL usage, scriptlet avoidance, and XSS prevention in server-rendered pages.'
applyTo: '**/*.jsp'
---

# JSP Conventions

Hard rules for JSP files. Security rules in `instructions/security-and-owasp.instructions.md` still apply — this file covers JSP-specific template conventions and XSS prevention patterns.

## Output Encoding (XSS Prevention)

**Every dynamic value rendered in HTML must be encoded.** This is the single most important rule.

| Context | Safe | Unsafe |
|---|---|---|
| HTML body | `<c:out value="${user.name}"/>` | `${user.name}` (raw EL — no encoding) |
| HTML attribute | `<input value="<c:out value='${q}'/>" />` | `<input value="${q}" />` |
| JavaScript block | Avoid; pass data via `data-` attributes | `var x = '${userInput}';` |
| URL parameter | `${fn:escapeXml(param)}` or encode server-side | `href="?q=${param}"` |

- **Default stance: use `<c:out>` for ALL dynamic output.** Treat raw `${}` in HTML as a potential XSS vector.
- `fn:escapeXml()` is the JSTL equivalent for inline use: `${fn:escapeXml(value)}`.
- For content that must render HTML (rich text), sanitize server-side before passing to the JSP. Never use raw EL for user-generated HTML.

## JSTL Over Scriptlets

**Scriptlets (`<% %>`) are forbidden in new code.** Use JSTL + EL exclusively.

| Scriptlet (forbidden) | JSTL equivalent |
|---|---|
| `<% if (user != null) { %>` | `<c:if test="${not empty user}">` |
| `<% for (Item i : items) { %>` | `<c:forEach var="item" items="${items}">` |
| `<%= user.getName() %>` | `<c:out value="${user.name}"/>` |
| `<% String fmt = String.format(...); %>` | `<fmt:formatDate>`, `<fmt:formatNumber>` |

Required taglib declarations at the top of every JSP:

```jsp
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
```

## EL Expression Safety

- **Never call methods with side effects from EL** — EL is for reading, not mutating.
- **Null handling** — EL renders `null` as empty string, which is usually safe. Use `empty` operator for explicit checks: `${not empty list}`.
- **Type coercion** — EL silently coerces types. Be explicit when comparing: `${status eq 'ACTIVE'}` not `${status == 'ACTIVE'}` (the latter works but `eq` is clearer for string comparison).

## Page Structure

- **No business logic in JSP** — JSPs are view templates. Prepare all data in the servlet / controller and pass via request attributes.
- **No database calls from JSP** — ever.
- **No Java imports in JSP** — if you need `<%@ page import="..." %>`, the logic belongs in the servlet.
- Keep JSPs focused on rendering. Complex conditional logic is a sign the servlet should pre-compute the value.

## Include and Forward

- **`<jsp:include>`** for reusable fragments (header, footer, navigation).
- Place shared fragments in a `/WEB-INF/fragments/` or `/WEB-INF/includes/` directory.
- **Never expose JSP files directly** — all JSPs should live under `/WEB-INF/` and be accessed via servlet forward only.
- Set `Content-Type` and encoding in the servlet or page directive: `<%@ page contentType="text/html;charset=UTF-8" %>`.

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| Raw `${value}` in HTML | XSS — no output encoding | `<c:out value="${value}"/>` |
| `<%= request.getParameter("q") %>` | XSS + scriptlet | `<c:out value="${param.q}"/>` |
| Business logic in `<% %>` blocks | Unmaintainable, untestable | Move to servlet, pass via request attribute |
| Direct JSP access (not behind servlet) | Bypasses auth and validation | Place under `/WEB-INF/`, access via `RequestDispatcher.forward()` |
| `out.println()` in scriptlet | Bypasses template engine | Use JSTL tags |
| Inline `<style>` or `<script>` with `${}` | XSS in CSS/JS context | Use `data-` attributes, encode server-side |
