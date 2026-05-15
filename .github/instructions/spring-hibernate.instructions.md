---
description: 'Spring Core + Hibernate 4.x — native Session API, hbm.xml mappings, XML tx:advice transaction management.'
applyTo: '**/*.java, **/*.hbm.xml'
---

# Spring Core + Hibernate 4.x Conventions

No Spring Boot. No JPA annotations. AI models default to both — correct that here. SQL rules: `instructions/sql.instructions.md`.

## Hibernate API

- **Native Session** only — `SessionFactory.getCurrentSession()`, not JPA `EntityManager`
- **hbm.xml mappings** — one per entity, alongside POJO. No `@Entity` / `@Column` / `@OneToMany`
- HQL via `session.createQuery()`; classic `Criteria` for dynamic queries; `createSQLQuery()` as last resort
- Always named parameters (`:param`) — never concatenation, even in HQL
- `session.get()` over `session.load()` unless you need a lazy proxy
- `StatelessSession` for batch >1000 rows

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

## hbm.xml Patterns

- Root: `<hibernate-mapping package="...">` with explicit package
- Collections: `lazy="true"` explicit for intent visibility
- FK: `foreign-key="FK_<table>_<column>"`
- Second-level cache: opt-in per entity, never global

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `@Entity` / `@Column` on POJO | This project is hbm.xml only | Remove; metadata in hbm.xml |
| `@Transactional` on service | Conflicts with XML `<tx:advice>` | Remove; use `<tx:method>` entry |
| `sessionFactory.openSession()` in DAO | Session outside tx boundary | `getCurrentSession()` |
| `session.beginTransaction()` in advised code | Fights Spring tx sync | Let `<tx:advice>` handle it |
| Lazy collection accessed after tx commits | `LazyInitializationException` | `JOIN FETCH` or `Hibernate.initialize()` in service |
| `this.otherMethod()` for new tx | Self-invocation bypasses proxy | Inject proxied bean; call through reference |
| `for (u : users) { u.getOrders().size(); }` | N+1 queries | `JOIN FETCH` or `fetch="join"` in hbm.xml |
