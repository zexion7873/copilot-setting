---
description: 'XML conventions for Spring configuration, Hibernate hbm.xml, and Maven POM files.'
applyTo: '**/*.xml'
---

# XML Configuration Conventions

Conventions for Spring XML config (`applicationContext*.xml`), Hibernate `hbm.xml` mappings, and Maven POM files. Transaction management rules: `instructions/spring-hibernate.instructions.md`.

## Spring XML

- One config file per concern (e.g., `applicationContext-dao.xml`, `applicationContext-service.xml`)
- Bean IDs: camelCase, descriptive (`orderService`, `transactionManager`)
- Transaction: `<tx:advice>` + `<aop:config>` on service layer — see `instructions/spring-hibernate.instructions.md`

## Hibernate hbm.xml

- One file per entity: `<EntityName>.hbm.xml`, alongside the POJO
- Root: `<hibernate-mapping package="...">` with explicit package
- Collections: `lazy="true"` explicit; FK: `foreign-key="fk_<child>_<parent_col>"` (match SQL DDL — see `instructions/sql.instructions.md`)

## Maven POM

- Pin all dependency versions — no ranges, no `SNAPSHOT` in releases
- `<dependencyManagement>` for version centralization in multi-module
- Encoding: `<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>`

## General

- Indentation: 4 spaces for Spring/hbm.xml; 2 spaces for POM
- Close all tags; self-closing for empty elements
- Comment only non-obvious configuration choices

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `spring-beans-4.0.xsd` in namespace | Schema version exceeds Spring 3.2 runtime — silent misconfiguration | Use `spring-beans-3.2.xsd` (match actual framework version) |
| `<tx:annotation-driven/>` | Conflicts with project's `<tx:advice>` + `<aop:config>` transaction strategy | Remove; use `<tx:advice>` — see `instructions/spring-hibernate.instructions.md` |
| `<context:component-scan base-package="com.example"/>` | Scans entire package tree — picks up test doubles, unintended beans | Narrow to specific subpackage: `com.example.service` |
| `<hibernate-mapping>` without `package` | Every `<class>` needs FQCN; noisy and error-prone | Add `package="com.example.entity"` on root element |
| `<version>[1.0,2.0)</version>` | Version range — non-reproducible builds | Pin exact version: `<version>1.2.3</version>` |
| `<version>2.0-SNAPSHOT</version>` in release POM | SNAPSHOT in release — build depends on mutable artifact | Release with fixed version; strip `-SNAPSHOT` before tagging |
