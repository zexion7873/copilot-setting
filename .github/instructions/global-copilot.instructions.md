---
name: 'Global Copilot Instructions'
description: 'Global coding standards, conventions, and guidelines for all projects'
applyTo: '**'
---

# Global Copilot Instructions

## Language & Communication

- Always respond in **Traditional Chinese (繁體中文)**.
- All code, comments, variable names, and documentation within code must be in **English**.
- Keep responses concise and direct. Avoid unnecessary verbosity.

## Tech Stack

- Primary language: **Java 8** (planned upgrade to Java 21 in the future)
- Build tool: **Maven**
- No Spring Boot — follows Java SE and Jakarta EE conventions

## Code Style

- Variables and methods: **camelCase** (e.g., `findActiveUserById`)
- Classes and interfaces: **PascalCase** (e.g., `UserService`)
- Constants: **UPPER_SNAKE_CASE** (e.g., `MAX_RETRY_COUNT`)
- Method names should clearly describe intent — prefer `findActiveUserById` over `getUser`
- Each method should have a single responsibility and ideally stay under 30 lines
- Avoid nesting beyond 3 levels of if/for blocks
- Use meaningful variable names — no single-letter names except loop indices (`i`, `j`, `k`)

## Comments

- Use Javadoc format for public APIs
- Comments should explain **why**, not **what**
- Avoid redundant comments (e.g., `// get user` above `getUser()`)
- Complex business logic must have explanatory comments

## Error Handling

- Empty catch blocks are not allowed
- Error messages must include sufficient context information
- Prefer specific exception types — avoid catching `Exception` or `Throwable`
- Handle exceptions at the appropriate level — do not swallow errors in low-level code

## Git & Commit

- Follow [Conventional Commits](https://www.conventionalcommits.org/) format (e.g., `feat:`, `fix:`, `refactor:`, `docs:`)
- Commit messages must be in **English**
- Keep commits small and focused — one logical change per commit
- Write clear, descriptive commit messages that explain **why**, not just **what**

## Logging

- Use **SLF4J** as the logging facade with **Logback** as the implementation
- Use appropriate log levels:
  - `ERROR` — unexpected failures that require immediate attention
  - `WARN` — recoverable issues or degraded functionality
  - `INFO` — key business events and application lifecycle (startup, shutdown)
  - `DEBUG` — detailed diagnostic information for development and troubleshooting
- Include sufficient context in log messages (e.g., user ID, request ID, relevant parameters)
- Never log sensitive data (passwords, tokens, PII)
- Use parameterized logging — `log.info("User {} logged in", userId)` instead of string concatenation

## Security Basics

- Never hardcode passwords, API keys, or secrets in source code
- All user inputs must be validated and sanitized
- SQL queries must use parameterized queries (PreparedStatement) — no string concatenation
- Sensitive data must not appear in log output

## Performance Awareness

- Watch for database queries inside loops (N+1 problem)
- SELECT only the columns you need — avoid SELECT *
- Use caching where appropriate to reduce redundant computation or queries
- Process large datasets with pagination or streaming
