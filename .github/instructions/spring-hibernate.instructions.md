---
description: 'Spring 3.2 + Hibernate 4.2 — native Session API, hbm.xml mappings, XML tx:advice, and Spring 3.2 API boundary.'
applyTo: '**/*.java, **/*.hbm.xml'
---

# Spring 3.2 + Hibernate 4.2 Conventions

No Spring Boot, no Spring 4+, no JPA annotations — AI defaults to all three. SQL rules: `instructions/sql.instructions.md`.

## Spring 3.2 Boundary — Forbidden (Spring 4+)

- `@RestController` → `@Controller` + `@ResponseBody`
- `@GetMapping` / `@PostMapping` / `@PutMapping` / `@DeleteMapping` / `@PatchMapping` → `@RequestMapping(method = RequestMethod.GET)` etc.
- `@Conditional` (Spring 4.0) — note: `@Profile` itself is Spring **3.1** and allowed, and single-profile negation (`!dev`, SPR-8728) works since **3.2**; only compound profile *expressions* (`&` / `|` in the value, Spring 5.1) are out
- `AsyncRestTemplate`, `ListenableFuture`
- Spring 4 test annotations (`@Sql`, `@SqlGroup`)

## Forbidden by Project Convention (valid in 3.2, not used here)

- `AbstractAnnotationConfigDispatcherServletInitializer` — exists since Spring 3.2, but this project bootstraps via `web.xml`; do not introduce servlet initializers

## Hibernate 4.2 API

- Native Session only — `SessionFactory.getCurrentSession()`, never JPA `EntityManager`
- hbm.xml mappings, one per entity beside its POJO — no `@Entity` / `@Column` / `@OneToMany`
- Queries: HQL via `session.createQuery()`; classic `Criteria` for dynamic; `createSQLQuery()` last resort
- Named parameters (`:param`) only — never concatenation, even in HQL
- `session.get()` over `session.load()` unless you need a lazy proxy
- `StatelessSession` for large batches — bypasses the first-level cache (no dirty-check / flush / cascade); switch when persistence-context growth or flush cost dominates, not at a fixed row count
- `session.byId()` / `session.byNaturalId()` (fluent load-access, added in Hibernate 4.1) work in 4.2 — allowed, but prefer `session.get()` / HQL / `Criteria` for house consistency
- MySQL 8.0 dialect/driver gap: Hibernate 4.2 ships no MySQL 8 dialect — use `org.hibernate.dialect.MySQL5Dialect` (or `MySQL5InnoDBDialect`); `MySQL57Dialect` / `MySQL8Dialect` arrived in Hibernate 5.x / 5.3 and do NOT exist in 4.2, so never copy them from a 5.x or Spring Boot tutorial. MySQL 8.0's default `caching_sha2_password` auth needs Connector/J 8.0.x (or set the DB account to `mysql_native_password`)

## Session Lifecycle (DAOs)

- Use `getCurrentSession()` — Spring binds it to the active transaction
- Never `openSession()` (unmanaged session), `close()` / `flush()` (Spring owns lifecycle), or pass a Session across threads (not thread-safe)

## Lazy Loading — pick ONE per module, never mix

- `OpenSessionInViewFilter` (web.xml) — Session open through JSP render; simplest for read-heavy pages; risk: hidden N+1. Even with OSIV, prepare view data in the service layer — it is a safety net against `LazyInitializationException`, not license for the JSP to drive lazy loads (`instructions/jsp.instructions.md`)
- DTO projection — assemble DTOs in service, JSP never touches entities; safest for APIs; more boilerplate
- `JOIN FETCH` / `Hibernate.initialize()` — eager-load required associations in service; middle ground, easy to miss paths

`LazyInitializationException` in JSP = Session closed before render. Fix by adopting one strategy above — never suppress it.

## Transaction Management (XML AOP)

- `HibernateTransactionManager` + `<tx:advice>` + `<aop:config>` pointcut on the service layer; DAOs are pure data access
- Forbidden: `@Transactional` (new code); manual `beginTransaction()` / `commit()` / `rollback()` in advised methods
- Read-only `<tx:method read-only="true">` for `get*` / `find*` / `list*` / `count*`
- Rollback auto on `RuntimeException` / `Error`; checked exceptions need `rollback-for`
- Self-invocation (`this.method()`) bypasses the proxy — call through an injected bean for a new tx
- Legacy exception: if the codebase is already consistently `@Transactional`, sustain it rather than mixing modes; greenfield modules default to `<tx:advice>`; document any deviation in the module README or `package-info`

## hbm.xml Patterns

- Root `<hibernate-mapping package="...">` with explicit package
- Collections `lazy="true"` explicit for intent
- FK naming `foreign-key="fk_<child>_<parent_col>"` — match the SQL DDL convention so Hibernate-generated and hand-written DDL agree (`instructions/sql.instructions.md`)
- Second-level cache opt-in per entity, never global

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `@Entity` / `@Column` on POJO | This project is hbm.xml only | Remove; metadata in hbm.xml |
| `@RestController` | Spring 4+ — does not exist in 3.2 | `@Controller` + `@ResponseBody` |
| `@Transactional` on service (new code) | Conflicts with XML `<tx:advice>` | Use `<tx:method>` entry — unless the legacy codebase is already `@Transactional`-based; then sustain existing convention |
| `sessionFactory.openSession()` in DAO | Session outside tx boundary | `getCurrentSession()` |
| `session.beginTransaction()` in advised code | Fights Spring tx sync | Let `<tx:advice>` handle it |
| Lazy collection accessed after tx commits | `LazyInitializationException` | `JOIN FETCH` or `Hibernate.initialize()` in service |
| `this.otherMethod()` for new tx | Self-invocation bypasses proxy | Inject proxied bean; call through reference |
| `for (u : users) { u.getOrders().size(); }` | N+1 queries | `JOIN FETCH` or `fetch="join"` in hbm.xml |
