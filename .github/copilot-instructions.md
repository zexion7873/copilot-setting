# Global Copilot Instructions

## Language & Communication

- Always respond in **Traditional Chinese (繁體中文)**.
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

## Coding Philosophy

- Minimum code that solves the problem. No speculative abstractions, no features beyond what was asked.
- When uncertain, ask — don't assume. One round of clarifying questions before acting.
