# Global Copilot Instructions

## Language & Communication

- Always respond in **Traditional Chinese (繁體中文)**.
- Keep responses concise and direct. Avoid unnecessary verbosity.

## Tech Stack

- **Java 8** — WAR packaging, servlet container. No `var`, `List.of()`, records, sealed classes, text blocks, module system.
- **Maven**
- **Spring 3.2** — XML config + `<tx:advice>` only. No Spring Boot, no `@RestController`, no `@Conditional`, no `@Transactional`.
- **Spring Security 3.2** — XML namespace config
- **Hibernate 4.2** — native Session API, `hbm.xml` mappings, `getCurrentSession()`. No JPA annotations.
- **MySQL 8.0** — InnoDB, utf8mb4
- **SLF4J 1.7** + Logback
- **JSP + JSTL 1.2** — view layer
- **SQL** — `PreparedStatement` with `?` (JDBC); named params `:param` (HQL). Zero string concatenation.
- **File operations** — use editing tools, never terminal heredoc / redirection (`cat >`/`echo >>`/`<< EOF`)

## Coding Philosophy

### Think Before Coding

- State assumptions explicitly. If uncertain, ask — don't guess.
- If multiple interpretations exist, present them. Don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.

### Simplicity First

- Minimum code that solves the problem. No speculative abstractions, no features beyond what was asked.
- No "flexibility" or "configurability" that wasn't requested.
- If 200 lines could be 50, rewrite it.

### Surgical Changes

- Touch only what the task requires. Don't "improve" adjacent code, comments, or formatting.
- Match existing style, even if you'd do it differently.
- Clean up orphans YOUR changes created. Don't remove pre-existing dead code — mention it, don't delete it.
