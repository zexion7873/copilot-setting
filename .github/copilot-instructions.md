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

**Hard boundary — not a style preference.** Do NOT use APIs, annotations, or patterns from newer versions of these frameworks. The pull toward modern idioms is a bias to resist, not a hint to follow — and the build won't catch it: many such symbols compile clean and fail only at review or runtime. If unsure whether something exists in these versions, read the matching `instructions/` file before writing code; never guess.

## Coding Philosophy

- State assumptions explicitly. If uncertain, ask — don't guess.
- If multiple interpretations exist, present them. Don't pick silently.
- Minimum code that solves the problem — no speculative abstractions, no features beyond what was asked.
- Touch only what the task requires; match existing style, even if you'd do it differently.
- Clean up orphans YOUR changes created. Don't remove pre-existing dead code — mention it, don't delete it.

## File Operations

- Never use `cat`/`echo`/`printf`/`tee` with `>`/`>>`/`<< EOF` to write file content — VS Code terminal integration corrupts these (tab completion, escaping, exit 130).
- Create / modify files with the file editing tools (Write / Edit); `rm` is fine for deletion.
- Terminal remains fine for package management, builds, tests, git, `ls`/`mkdir`/`rm`, and downloads that don't pipe into files.
