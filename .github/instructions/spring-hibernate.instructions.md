---
description: 'Load when writing or reviewing Java or hbm.xml on a Spring 3.2 + Hibernate 4.2 stack — native Session API, XML mappings/tx, Spring MVC. Triggers on: getCurrentSession (not openSession), hbm.xml (not JPA @Entity), <tx:advice> (not @Transactional), @Controller/@RequestMapping (not @GetMapping). No Spring Boot/JPA. Defer SQL to sql.instructions.md.'
applyTo: '**/*.java, **/*.hbm.xml'
---

# Spring 3.2 + Hibernate 4.2 Conventions

No Spring Boot, Spring 4+, or JPA — AI defaults to all three. SQL: `instructions/sql.instructions.md`.

## Forbidden

- `@RestController` → `@Controller` + `@ResponseBody`
- `@GetMapping`/`@PostMapping`/`@PutMapping`/`@DeleteMapping`/`@PatchMapping` → `@RequestMapping(method = RequestMethod.GET)` etc.
- `@Conditional` (4.0). `@Profile` (3.1) and `!dev` negation (3.2) OK; compound `&`/`|` expressions (5.1) not
- `AsyncRestTemplate`, `ListenableFuture`; Spring 4 test annotations (`@Sql`, `@SqlGroup`)
- `AbstractAnnotationConfigDispatcherServletInitializer` — valid in 3.2 but unused; bootstrap via `web.xml` only

## Hibernate 4.2 API

- Native Session only — `SessionFactory.getCurrentSession()`, never JPA `EntityManager`
- hbm.xml mappings, one per entity beside its POJO — no `@Entity`/`@Column`/`@OneToMany`
- HQL `createQuery()`; `Criteria` for dynamic; `createSQLQuery()` last resort; named params (`:param`) only, never concatenation
- `session.get()` over `load()` unless a lazy proxy is needed
- `StatelessSession` for large batches (no first-level cache/dirty-check/flush/cascade); switch when flush/context cost dominates, not at a fixed row count
- `byId()`/`byNaturalId()` (4.1+) allowed; prefer `get()`/HQL/`Criteria`
- Dialect: `MySQL5Dialect`/`MySQL5InnoDBDialect` — `MySQL57Dialect`/`MySQL8Dialect` are Hibernate 5.x, do NOT exist in 4.2. MySQL 8.0 `caching_sha2_password` needs Connector/J 8.0.x (or `mysql_native_password`)
- DAOs: `getCurrentSession()` only (Spring binds it to the active tx); never `openSession()`, `close()`/`flush()` (Spring owns lifecycle), or pass a Session across threads

## Lazy Loading — pick ONE per module, never mix

- `OpenSessionInViewFilter` (web.xml) — simplest for read-heavy pages; a safety net, not license for JSP lazy loads — prep view data in the service (`instructions/jsp.instructions.md`)
- DTO projection in service — JSP never touches entities; safest for APIs
- `JOIN FETCH`/`Hibernate.initialize()` in service — middle ground, easy to miss paths

`LazyInitializationException` in JSP = Session closed before render; adopt one strategy, never suppress.

## Transactions (XML AOP)

- `HibernateTransactionManager` + `<tx:advice>` + `<aop:config>` pointcut on services; DAOs stay pure data access
- Forbidden: `@Transactional` (new code); manual `beginTransaction()`/`commit()`/`rollback()` in advised methods
- `<tx:method read-only="true">` for `get*`/`find*`/`list*`/`count*`
- Auto rollback on `RuntimeException`/`Error`; checked exceptions need `rollback-for`
- Self-invocation (`this.method()`) bypasses the proxy — call through an injected bean
- Legacy exception: sustain an already-consistent `@Transactional` codebase (never mix); greenfield uses `<tx:advice>`; document deviations

## hbm.xml

- Root `<hibernate-mapping package="...">`; collections `lazy="true"` explicit
- `foreign-key="fk_<child>_<parent_col>"` — matches SQL DDL convention (`instructions/sql.instructions.md`)
- Second-level cache opt-in per entity, never global

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `@Entity`/`@Column` on POJO | hbm.xml-only project | Metadata in hbm.xml |
| `@Transactional` on new service code | Conflicts with `<tx:advice>` | `<tx:method>` entry |
| `sessionFactory.openSession()` in DAO | Session outside tx boundary | `getCurrentSession()` |
| Lazy access after tx commit | `LazyInitializationException` | `JOIN FETCH`/`Hibernate.initialize()` in service |
| `for (u : users) { u.getOrders().size(); }` | N+1 queries | `JOIN FETCH` or `fetch="join"` in hbm.xml |
