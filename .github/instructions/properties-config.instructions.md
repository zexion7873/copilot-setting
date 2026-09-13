---
description: 'Load when writing or reviewing a .properties config file — Hibernate 4.2 and JDBC settings that fail silently or leak. Triggers on: hibernate.dialect, hibernate.hbm2ddl.auto, jdbc.password, jdbc.url, connectionTimeZone/serverTimezone, Connector/J. No Spring Boot application.properties. Defer XML config to xml-config.instructions.md.'
applyTo: '**/*.properties'
---

# Properties Configuration Conventions

Values loaded by `<context:property-placeholder>` into the Spring XML context (`instructions/xml-config.instructions.md`). This is not a Spring Boot `application.properties` — no relaxed binding, no auto-configuration, no profile-specific defaults.

## Hibernate

- `hibernate.dialect` is `org.hibernate.dialect.MySQL5Dialect` or `MySQL5InnoDBDialect` — **`MySQL8Dialect` and `MySQL57Dialect` do not exist in Hibernate 4.2** (they arrived in 5.x). The MySQL server version is irrelevant here; 4.2 resolves any MySQL 5+ server to the 5 dialect (`instructions/spring-hibernate.instructions.md`)
- `hibernate.hbm2ddl.auto=validate`, or omit the property entirely — never `update` / `create` / `create-drop`. `update` mutates the live schema at startup, outside the reviewed migration scripts and their rollbacks (`instructions/sql-ddl.instructions.md`), and the damage is not reversible from the application side

## Credentials & Connection

- No plaintext `jdbc.password` in a file that ships with the build — inject from an environment variable or a secret store (`instructions/security.instructions.md`)
- Pin the connection time zone in the JDBC URL rather than relying on the driver default: `connectionTimeZone=` on Connector/J 8.0.23+, `serverTimezone=` on 8.0.22 and earlier (still accepted as an alias). Left unset, a server whose zone resolves to an ambiguous abbreviation (CST, CET) fails with "The server time zone value ... is unrecognized"
