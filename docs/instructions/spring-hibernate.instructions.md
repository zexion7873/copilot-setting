---
description: 'Spring 3.2 + Hibernate 4.2 — native Session API, hbm.xml mappings, XML tx:advice, and Spring 3.2 API boundary.'
applyTo: '**/*.java, **/*.hbm.xml'
# Author reference only. Runtime rules are embedded in agents/*.agent.md (Coding Standards section).
# This file still auto-loads via applyTo when a matching file is focused (bonus reinforcement).
---

# Spring 3.2 + Hibernate 4.2 Conventions

No Spring Boot. No Spring 4+. No JPA annotations. AI models default to all three — correct that here. SQL rules: `instructions/sql.instructions.md`.

## Spring 3.2 Boundary (Spring 4+ Forbidden)

- `@RestController` — use `@Controller` + `@ResponseBody`
- `@Conditional`, `@Profile` with complex conditions
- `AsyncRestTemplate`, `ListenableFuture`
- `AbstractAnnotationConfigDispatcherServletInitializer` — this project uses `web.xml`
- `RestTemplate.exchange()` with `ParameterizedTypeReference` (Spring 3.2 has basic `RestTemplate` only)
- Spring 4 test annotations (`@Sql`, `@SqlGroup`)

## Hibernate 4.2 API

- **Native Session** only — `SessionFactory.getCurrentSession()`, not JPA `EntityManager`
- **hbm.xml mappings** — one per entity, alongside POJO. No `@Entity` / `@Column` / `@OneToMany`
- HQL via `session.createQuery()`; classic `Criteria` for dynamic queries; `createSQLQuery()` as last resort
- Always named parameters (`:param`) — never concatenation, even in HQL
- `session.get()` over `session.load()` unless you need a lazy proxy
- `StatelessSession` for batch >1000 rows
- No `Session.byId()`, `Session.byNaturalId()` — those are Hibernate 5+

## Session Lifecycle

- DAOs: `sessionFactory.getCurrentSession()` — Spring binds to active transaction
- **Never** `openSession()` in DAOs — creates unmanaged session
- **Never** `session.close()` / `flush()` in DAOs — Spring owns lifecycle
- **Never** pass session across threads — not thread-safe

## Transaction Management (tx:advice)

- `HibernateTransactionManager` + `<tx:advice>` + `<aop:config>` pointcut on service layer
- **Forbidden**: `@Transactional` — this project uses XML AOP exclusively
- **Forbidden**: manual `beginTransaction()` / `commit()` / `rollback()` inside advised methods
- Transactions in service layer; DAOs are pure data access
- Read-only: `<tx:method>` with `read-only="true"` for `get*`, `find*`, `list*`, `count*`
- Rollback: automatic on `RuntimeException` / `Error`; checked exceptions need `rollback-for`
- Self-invocation (`this.method()`) bypasses proxy — call through injected bean for new tx
- **Pragmatic exception (legacy codebase)**: if the target codebase already uses `@Transactional` consistently, sustain the existing convention rather than introducing mixed XML/annotation mode. Greenfield modules in this project still default to `<tx:advice>`. When deviating, document the reason in the module's README or top-level package-info.

## hbm.xml Patterns

- Root: `<hibernate-mapping package="...">` with explicit package
- Collections: `lazy="true"` explicit for intent visibility
- FK: `foreign-key="FK_<table>_<column>"`
- Second-level cache: opt-in per entity, never global

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
