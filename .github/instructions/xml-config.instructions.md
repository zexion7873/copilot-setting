---
description: 'Load when writing or reviewing stack XML — Spring applicationContext, hbm.xml, web.xml, or Maven pom.xml. Triggers on: <tx:advice> (not <tx:annotation-driven>), spring-beans-3.2.xsd (not 4.0), <hibernate-mapping>, DispatcherServlet, <dependencyManagement>, scope test/provided, source/target 1.8, no -SNAPSHOT/LATEST. No Spring Boot. Defer SQL/Java to their files.'
applyTo: '**/*.xml'
---

# XML Configuration Conventions

Transaction management rules: `instructions/spring-hibernate.instructions.md`.

## Spring XML

- One config file per concern (`applicationContext-dao.xml`, `applicationContext-service.xml`)
- Bean IDs: camelCase, descriptive (`orderService`)
- Transactions: `<tx:advice>` + `<aop:config>` on the service layer

## Hibernate hbm.xml

- One file per entity: `<EntityName>.hbm.xml`, alongside the POJO
- Root `<hibernate-mapping package="...">` with explicit package
- Collections: explicit `lazy="true"`; FK: `foreign-key="fk_<child>_<parent_col>"` matching SQL DDL (`instructions/sql.instructions.md`)

## Maven POM

- Pin every dependency and plugin version — no ranges, no `SNAPSHOT` in releases, no `LATEST`/`RELEASE`
- `<dependencyManagement>` centralizes versions in multi-module builds
- Scopes: test libs (JUnit, Mockito) `<scope>test</scope>`; container APIs (servlet, JSP) `<scope>provided</scope>` — never bundled into the WAR
- `maven-compiler-plugin` `source`/`target` = `1.8`; `<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>`

## web.xml

Bootstrap is via `web.xml` — no servlet initializers (`instructions/spring-hibernate.instructions.md`):

- `<web-app>` version matches the container's servlet spec and Spring 3.2 — never declare a newer spec
- `CharacterEncodingFilter` (UTF-8) mapped **first**, before any filter that reads request parameters (`instructions/jsp.instructions.md`)
- Context split: `ContextLoaderListener` = root context (services, DAOs); `DispatcherServlet` = its own web context (controllers, view resolvers) — never redefine the same bean in both
- `OpenSessionInViewFilter`, if used, lives here — `instructions/spring-hibernate.instructions.md`

## General

- Indentation: 4 spaces (Spring/hbm.xml), 2 spaces (POM); close all tags, self-close empty elements; comment only non-obvious choices

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `spring-beans-4.0.xsd` | Exceeds Spring 3.2 runtime | `spring-beans-3.2.xsd` |
| `<tx:annotation-driven/>` | Conflicts with `<tx:advice>` + `<aop:config>` strategy | Remove in `<tx:advice>` modules; **keep** in consistently `@Transactional` legacy modules (`instructions/spring-hibernate.instructions.md`) |
| `<context:component-scan base-package="com.example"/>` | Scans entire tree — unintended beans | Narrow: `com.example.service` |
| `<hibernate-mapping>` without `package` | FQCN on every `<class>` | `package="com.example.entity"` |
| `<version>[1.0,2.0)</version>` or `2.0-SNAPSHOT` in release | Non-reproducible / mutable artifact | Pin exact release version |
