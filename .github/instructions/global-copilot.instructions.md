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
