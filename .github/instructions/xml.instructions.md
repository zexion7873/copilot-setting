---
description: 'XML conventions for Maven POM, web.xml, and configuration files — structure, formatting, and common pitfalls.'
applyTo: '**/*.xml'
---

# XML Conventions

Hard rules for XML files in Java 8 / Maven / Jakarta EE projects. SQL-related XML content follows rules from `instructions/sql-rules.instructions.md` — this file covers non-SQL XML conventions.

## General Formatting

- **Encoding declaration required** on every XML file: `<?xml version="1.0" encoding="UTF-8"?>`.
- **4-space indentation** for POM files; **2-space** for web.xml and config files. Pick one per file and never mix.
- **Namespace declarations** belong on the root element only. Never scatter them across child elements.
- **Schema references** (`xsi:schemaLocation`) must point to a versioned URL, not a floating `latest`.
- One element per line. No inline sibling elements on the same line.
- Closing tags on their own line when the element spans multiple lines.

## Maven POM Conventions

- **`<dependencyManagement>`** is for version pinning only. Never put direct project dependencies there without a corresponding `<dependencies>` entry.
- **All dependency versions via properties**: `<properties><slf4j.version>1.7.36</slf4j.version></properties>`. No hardcoded version strings in `<dependency>` blocks.
- **Scope explicitly declared** for non-compile dependencies: `test`, `provided`, `runtime`. Omitting scope means compile — only do that intentionally.
- **`<pluginManagement>`** for plugin version pinning; `<plugins>` for active configuration. Never configure a plugin only in `<pluginManagement>` if it needs to run.
- **Minimal POM principle**: only declare what differs from the parent or Maven defaults. Do not repeat inherited values.
- **Profiles** for environment-specific config only (`dev`, `prod`, `ci`). Never use profiles to toggle features that belong in application config.
- `<parent>` block must include `<relativePath/>` (empty tag) when the parent is a remote artifact, not a local module.

## web.xml Conventions

- **Servlet 3.0+ schema** (`web-app version="3.0"`) minimum. Do not use 2.3 or 2.4 schemas in new code.
- **Filter ordering matters**: declare filters in `<filter>` blocks first, then `<filter-mapping>` blocks in the intended execution order.
- **Security constraints** (`<security-constraint>`) must pair with `<login-config>`. Never declare one without the other.
- **Session timeout** must be explicit: `<session-config><session-timeout>30</session-timeout></session-config>`. Do not rely on container defaults.
- **Error pages** for at minimum `404` and `500`: `<error-page><error-code>500</error-code><location>/WEB-INF/error/500.jsp</location></error-page>`.
- **Welcome files** list must be explicit. Do not leave `<welcome-file-list>` empty or absent.
- Servlet `<load-on-startup>` must be a positive integer for servlets that must initialize at deploy time. Negative values mean lazy init — document why if used.

## Logback / Config XML

- **`<configuration>` root** with `scan="true"` and `scanPeriod` only in non-production profiles.
- Appender names in UPPER_SNAKE_CASE: `CONSOLE`, `FILE`, `ROLLING_FILE`.
- **Never hardcode absolute paths** in `<file>` or `<fileNamePattern>`. Use `${LOG_HOME}` or a system property.
- Pattern layouts must include `%d`, `%level`, `%logger{36}`, and `%msg%n` at minimum.

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| Version in `<dependency>` without property | Version scattered, hard to audit | Extract to `<properties>` |
| `<dependencyManagement>` without `<dependencies>` entry | Dependency declared but never used | Add `<dependency>` without version, or remove |
| Missing `encoding="UTF-8"` declaration | Container-default encoding, breaks on non-UTF-8 hosts | Always declare `<?xml version="1.0" encoding="UTF-8"?>` |
| Namespace on child elements | Redundant, noisy, confusing | Declare once on root element |
| `<security-constraint>` without `<login-config>` | Constraint defined but auth mechanism undefined | Always pair them |
| Floating schema URL (no version) | Schema may change under you | Pin to versioned URL |
| Plugin config only in `<pluginManagement>` | Plugin never executes | Move execution config to `<plugins>` |
