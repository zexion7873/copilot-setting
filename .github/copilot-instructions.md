# Global Copilot Instructions

## Language & Communication

- Always respond in **Traditional Chinese (繁體中文)**.
- Code, variable names, comments, and commit messages must be in **English**.
- Keep responses concise and direct. Avoid unnecessary verbosity.

## Tech Stack

- **Java 8** — WAR packaging, deployed to servlet container (not embedded server)
- **Maven**
- **Spring Framework 3.2** — not 4.x/5.x. No `@RestController`, no `@Conditional`. XML config + `<tx:advice>` for transactions
- **Spring Security 3.2** — XML namespace config
- **Hibernate 4.2** — native Session API (not JPA), `hbm.xml` mappings (not annotations), `getCurrentSession()`
- **MySQL 8.0** — InnoDB, utf8mb4
- **SLF4J 1.7** + Logback
- **JSP + JSTL 1.2** — view layer

**Hard boundary**: do NOT use APIs, annotations, or patterns from newer versions of these frameworks. When uncertain, read the matching instruction file under `instructions/` before writing code.

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
