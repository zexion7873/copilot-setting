---
description: 'XML conventions for Spring configuration, Hibernate hbm.xml, and Maven POM files.'
applyTo: '**/*.xml'
# Author reference only. Runtime rules are embedded in agents/*.agent.md (Coding Standards section).
---

# XML Configuration Conventions

## Spring XML

- One config file per concern (e.g., `applicationContext-dao.xml`, `applicationContext-service.xml`)
- Bean IDs: camelCase, descriptive (`orderService`, `transactionManager`)
- Transaction: `<tx:advice>` + `<aop:config>` on service layer — see `instructions/spring-hibernate.instructions.md`

## Hibernate hbm.xml

- One file per entity: `<EntityName>.hbm.xml`, alongside the POJO
- Root: `<hibernate-mapping package="...">` with explicit package
- Collections: `lazy="true"` explicit; FK: `foreign-key="FK_<table>_<column>"`

## Maven POM

- Pin all dependency versions — no ranges, no `SNAPSHOT` in releases
- `<dependencyManagement>` for version centralization in multi-module
- Encoding: `<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>`

## General

- Indentation: 4 spaces for Spring/hbm.xml; 2 spaces for POM
- Close all tags; self-closing for empty elements
- Comment only non-obvious configuration choices
