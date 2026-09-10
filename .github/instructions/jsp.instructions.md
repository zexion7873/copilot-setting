---
description: 'Load when writing or reviewing a .jsp view — XSS-safe encoding, JSTL-only (no scriptlets). Triggers on: c:out/fn:escapeXml, raw ${...}, <% %>/<%= %> scriptlets, EL in onclick/javascript:, JSON in <script>, view-layer LazyInitializationException. Defer XSS internals to security.instructions.md.'
applyTo: '**/*.jsp'
---

# JSP Conventions

## Output Encoding

- **Every** dynamic value: `<c:out value="${...}"/>` or `fn:escapeXml()` — no raw `${...}` in HTML
- Attribute context requires a **double-quoted** attribute — escaping cannot stop unquoted-attribute breakout
- Never put `${...}` in an inline event handler (`onclick`) or `javascript:` URL — escaping cannot make these safe; pass via an HTML-escaped `data-*` attribute and read it from JS
- JS context: JSON-encode server-side with `<` escaped as `\u003c`, or pass via a `data-*` attribute
- URL context: `<c:url>` with `<c:param>`

## JSTL Only

- No scriptlets (`<% ... %>`); no `<%= ... %>` — use `<c:out>`
- Logic: `<c:if>`, `<c:choose>`, `<c:forEach>`; formatting: `<fmt:formatDate>`, `<fmt:formatNumber>`

## Includes

- `<jsp:include>` for dynamic; `<%@ include %>` for static; never include user-supplied paths

## Data Preparation

- JSP must NOT trigger lazy loading — prepare all data in the controller/service before forwarding (`instructions/spring-hibernate.instructions.md`); a lazy-collection hit in a JSP means the service missed an eager fetch — fix the service, not the JSP
