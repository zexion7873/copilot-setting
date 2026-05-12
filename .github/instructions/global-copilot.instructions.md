---
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

## Git & Commit

- Follow [Conventional Commits](https://www.conventionalcommits.org/) format (e.g., `feat:`, `fix:`, `refactor:`, `docs:`)
- Commit messages must be in **English**
- Keep commits small and focused — one logical change per commit
- Write clear, descriptive commit messages that explain **why**, not just **what**

## Logging

- Use **SLF4J** facade with **Logback** implementation; parameterized only — `log.info("User {} logged in", userId)`
- Apply standard severity: `ERROR` (needs attention), `WARN` (recoverable), `INFO` (business events), `DEBUG` (diagnostics)
- Include context (user/request IDs, params); never log secrets, tokens, or PII
