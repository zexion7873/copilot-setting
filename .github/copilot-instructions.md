# Global Copilot Instructions

## Language & Communication

- Always respond in **Traditional Chinese (繁體中文)**.
- All code, comments, variable names, and documentation within code must be in **English**.
- Keep responses concise and direct. Avoid unnecessary verbosity.

## Tech Stack

- Primary language: **Java 8** (planned upgrade to Java 21 in the future)
- Build tool: **Maven**
- ORM: **Hibernate 4.x** — native Session API (not JPA EntityManager), `hbm.xml` mapping files (not annotations)
- No Spring Boot — follows Java SE and Jakarta EE conventions
