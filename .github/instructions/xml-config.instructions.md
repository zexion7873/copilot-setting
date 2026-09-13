---
description: 'Load when writing or reviewing stack XML — Spring applicationContext, spring-security.xml, hbm.xml, web.xml, or Maven pom.xml. Triggers on: <tx:advice> (not <tx:annotation-driven>), spring-beans-3.2.xsd (not 4.0), <hibernate-mapping>, DispatcherServlet, <dependencyManagement>, scope test/provided, source/target 1.8, no -SNAPSHOT/LATEST. No Spring Boot. Defer SQL/Java to their files.'
applyTo: '**/*.xml'
---

# XML Configuration Conventions

Conventions for Spring XML config (`applicationContext*.xml`), Hibernate `hbm.xml` mappings, and Maven POM files. Transaction management rules: `instructions/spring-hibernate.instructions.md`.

## Spring XML

- One config file per concern (e.g., `applicationContext-dao.xml`, `applicationContext-service.xml`)
- Bean IDs: camelCase, descriptive (`orderService`, `transactionManager`)
- Transaction: `<tx:advice>` + `<aop:config>` on service layer — see `instructions/spring-hibernate.instructions.md`
- Transaction manager bean is `org.springframework.orm.hibernate4.HibernateTransactionManager` with the `sessionFactory` from `org.springframework.orm.hibernate4.LocalSessionFactoryBean` — the `hibernate3` package and `DataSourceTransactionManager` both leave the Session unbound, so every `getCurrentSession()` throws
- A `<tx:advice>` with no `<aop:config><aop:advisor advice-ref="..."/>` is inert: nothing auto-proxies a bare advice, the context starts clean with no warning, and every service method runs non-transactional. An advisor whose pointcut matches nothing fails the same silent way — verify by observing a rollback, not by reading the XML
- `<tx:method>`: `read-only="true"` for `get*` / `find*` / `list*` / `count*`, and `rollback-for` on any method that throws a checked exception — without it Spring commits the transaction the service threw to abort (`instructions/spring-hibernate.instructions.md`)
- A test-scoped context declares its own `dataSource` — never point it at the live database: test-class `@Transactional` auto-rollback does not cover DDL or anything a stored procedure commits

## Spring Security XML

Spring Security 3.2 predates the 4.0 secure-by-default flip. Every rule here is a default a 4.x-trained model assumes it does not have to write.

- `<csrf/>` and `<headers/>` are both **off unless declared** inside `<http>` (4.0 turned both on by default) — omit them and the app has neither CSRF protection nor security headers, with no error. The 3.2 XSD has no `disabled` attribute on `<csrf>`, so a `<csrf disabled="true"/>` copied from 4.x fails schema validation
- A bare `<headers/>` installs the full 3.2 default set (`nosniff`, `X-Frame-Options: DENY`, `X-XSS-Protection`, cache-control, HSTS on HTTPS). Adding **any** child element replaces the whole set rather than extending it — `<headers><frame-options policy="SAMEORIGIN"/></headers>` silently drops the other four; list every header you still want. 4.0's `defaults-disabled` attribute does not exist in 3.2
- `<http use-expressions="true">` is required before any `access="hasRole(...)"` — 3.2 defaults it to `false` (4.0 flipped it), and without it the expression is parsed as a literal config attribute that no voter supports, aborting context startup with `IllegalArgumentException: Unsupported configuration attributes`
- `hasRole('X')` in 3.2 matches the granted authority **exactly and adds no `ROLE_` prefix** (4.0 introduced the prefixing) — write `hasRole('ROLE_ADMIN')`. This one fails silently: the user holding `ROLE_ADMIN` is simply denied with a 403, no startup error and nothing in the log
- Password encoding: `<password-encoder hash="bcrypt"/>` under `<authentication-provider>` (needs `spring-security-crypto`); never pair it with `<salt-source>` — bcrypt salts internally and the parser rejects the combination outright (`instructions/security.instructions.md`)
- Force HTTPS with **one** mechanism, not both: `<intercept-url requires-channel="https"/>` here, or `<transport-guarantee>CONFIDENTIAL</transport-guarantee>` in web.xml. Behind a TLS-terminating proxy either one loops redirects unless Tomcat's `RemoteIpValve` is configured

## Hibernate hbm.xml

hbm.xml mapping conventions (file-per-entity, root package, lazy/FK naming): see `instructions/spring-hibernate.instructions.md`.

## Maven POM

- Pin all dependency versions — no ranges, no `SNAPSHOT` in releases, no dynamic `LATEST`/`RELEASE` markers
- `<dependencyManagement>` for version centralization in multi-module
- Scopes: test-only libraries (JUnit, Mockito) use `<scope>test</scope>`; container-provided APIs (servlet, JSP) use `<scope>provided</scope>` — never bundle them into the WAR
- `maven-compiler-plugin` with `source`/`target` = `1.8`; pin every plugin version (unpinned plugins follow Maven defaults — non-reproducible builds)
- Encoding: `<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>`
- `junit:junit` 4.x — never `org.junit.jupiter:junit-jupiter`: the test sources on this stack are JUnit 4 (`instructions/testing.instructions.md`), and a Surefire older than 2.22 has no JUnit 5 provider, so JUnit 5 tests are not run rather than failed
- Against a MySQL 8 server use `mysql-connector-java` 8.0.x with driver class `com.mysql.cj.jdbc.Driver` — 5.1.x cannot handle the `caching_sha2_password` plugin that MySQL 8 assigns by default, so any account left on the server default fails to connect (an account explicitly set to `mysql_native_password` still works on 5.1.x, which is why this surfaces per-account rather than all at once)

## web.xml

This stack bootstraps via `web.xml` (no servlet initializers — see `instructions/spring-hibernate.instructions.md`), so these conventions apply:

- `<web-app>` version matches the container's servlet spec and the Spring 3.2 runtime — do not declare a newer spec than the container provides
- `CharacterEncodingFilter` set to UTF-8 and mapped **first** in the filter chain, before any filter that reads request parameters (ties into the JSP output-encoding story — `instructions/jsp.instructions.md`)
- Context split: `ContextLoaderListener` loads the root context (services, DAOs); `DispatcherServlet` loads only its own web context (controllers, view resolvers) — do not redefine the same bean in both
- `OpenSessionInViewFilter` (OSIV), if used, is configured here — see `instructions/spring-hibernate.instructions.md`
- Declare a catch-all `<error-page>` carrying only a `<location>` (Servlet 3.0 permits the form with neither `<error-code>` nor `<exception-type>`) — without it Tomcat 7's `ErrorReportValve` serves its own page, exposing the stack trace and the Tomcat version string (`instructions/security.instructions.md`)

## Version-Lock Traps (silent failures)

- `spring-beans-4.0.xsd` in a namespace declaration — schema version exceeds the Spring 3.2 runtime and misconfigures silently; use `spring-beans-3.2.xsd` to match the actual framework version
- `<tx:annotation-driven/>` conflicts with this project's `<tx:advice>` + `<aop:config>` strategy — remove it in greenfield / `<tx:advice>` modules, but **keep** it if the module is consistently `@Transactional`-based: removing it silently disables every annotated transaction (see the legacy exception in `instructions/spring-hibernate.instructions.md`)
- `<context:component-scan base-package="com.example"/>` scans the entire package tree and picks up test doubles and unintended beans — narrow it to specific subpackages
- `MySQL8Dialect` / `MySQL57Dialect` in a `sessionFactory` bean — neither exists in Hibernate 4.2 (they arrived in 5.x); use `org.hibernate.dialect.MySQL5Dialect` or `MySQL5InnoDBDialect`, and never copy a dialect from a Hibernate 5.x or Spring Boot tutorial (`instructions/spring-hibernate.instructions.md`)
