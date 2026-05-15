---
description: 'Hibernate 4.x conventions — native Session API, hbm.xml mappings, session lifecycle, transaction patterns, and Hibernate-specific anti-patterns.'
applyTo: '**/*.java, **/*.hbm.xml'
---

# Hibernate Conventions

Hard rules for Hibernate 4.x using native Session API plus `hbm.xml` mappings. Cross-references: `instructions/sql-rules.instructions.md` for raw JDBC fallback paths, `instructions/error-handling.instructions.md` for DAO-layer exception translation, `instructions/xml.instructions.md` for general XML conventions that apply to `hbm.xml` files.

## API Style

- Use **Hibernate native Session**, not JPA `EntityManager`. Inject `SessionFactory`; obtain `Session` per operation.
- Do NOT mix JPA annotations (`@Entity`, `@Column`, `@OneToMany`) with `hbm.xml` on the same entity — pick one. Default for new entities: `hbm.xml`.
- Queries: HQL via `session.createQuery(...)`; classic `Criteria` API (`session.createCriteria(...)`) for dynamic queries; native SQL via `session.createSQLQuery(...)` only when HQL and Criteria cannot express it.
- Use `StatelessSession` for batch operations exceeding ~1000 rows.

## Mapping — `hbm.xml`

- One mapping file per entity. File name: `<EntityName>.hbm.xml`, placed alongside the entity POJO.
- Root element: `<hibernate-mapping package="...">` with explicit `package` attribute — avoids fully qualified class names on every `<class>` declaration.
- Property access is the default (no need to declare `access="property"`). Use field access only when intentionally bypassing getters.
- Collection mappings (`<set>`, `<bag>`, `<list>`) — explicitly declare `lazy="true"` even though it is the Hibernate 4 default; intent should be visible.
- Foreign key declarations via `<many-to-one>` / `<one-to-many>` with `column` attribute. Name FK constraints explicitly with `foreign-key="FK_<table>_<column>"`.
- Second-level cache (`<cache usage="...">`) — opt in per entity, never as a global default.
- Entity POJOs stay annotation-free — all metadata lives in `hbm.xml`.

## Session Lifecycle

- **One session per unit of work** — open at the start, close at the end. Never reuse a session across HTTP requests or threads.
- Prefer `sessionFactory.openSession()` over `getCurrentSession()` unless a `CurrentSessionContext` is configured.
- Always close in `finally`:

```java
Session session = sessionFactory.openSession();
try {
    // work
} finally {
    session.close();
}
```

- `Session` is **not thread-safe**. Never pass between threads.
- Long-running sessions (>5 seconds) are a code smell — split into smaller units of work.

## Query Patterns

| Use case | API |
|---|---|
| Static query with known fields | HQL — `session.createQuery("FROM User u WHERE u.email = :email")` |
| Dynamic filters (search forms) | Criteria — `session.createCriteria(User.class).add(Restrictions.eq(...))` |
| Complex aggregation / DB-specific functions | Native SQL — `session.createSQLQuery(...).addEntity(User.class)` |
| Batch insert / update | `StatelessSession`, or flush + clear every 50 rows |

- Always use **named parameters** (`:paramName`). Never string concatenation — same rule as `instructions/sql-rules.instructions.md`, and also applies to HQL.
- Pagination: `query.setFirstResult(offset).setMaxResults(limit)`. Avoid large offsets — prefer keyset pagination on indexed columns.

## Transaction Management

The codebase does not currently have a unified transaction pattern. When writing new DAO code, use this baseline — explicit, minimal, and consistent:

```java
Session session = sessionFactory.openSession();
Transaction tx = null;
try {
    tx = session.beginTransaction();
    // DML work
    tx.commit();
} catch (Exception e) {
    if (tx != null && tx.isActive()) tx.rollback();
    throw e;
} finally {
    session.close();
}
```

- **Every DML operation must run inside a transaction.** No exceptions.
- Read-only operations may skip an explicit transaction, but must still close the session in `finally`.
- On exception: rollback FIRST, then rethrow. Never swallow.
- Do NOT nest transactions on the same session — Hibernate 4 has no real nested-transaction support; use JDBC savepoints if needed.
- `@Transactional` annotation has **no effect** without a CDI container or Spring proxy — do not use it in this project.

## Hibernate 4 Specific Notes

- `Session.load()` returns a proxy without hitting the DB; `Session.get()` hits the DB and returns `null` if not found. Default to `get()` unless you specifically need a lazy reference.
- `saveOrUpdate()` and `merge()` are NOT equivalent:
  - `saveOrUpdate()` — works on transient and detached entities with matching ID; throws on conflict with managed state.
  - `merge()` — copies state into a managed entity and returns it; safer when entity might already be in the session.
- Classic `Criteria` API is the standard in 4.x (deprecated only from 5.2). Do NOT switch to `javax.persistence.criteria.*` in this codebase.
- `HibernateException` is unchecked. DAO methods should translate it to a project-specific data-access exception at the DAO boundary — see `instructions/error-handling.instructions.md`.
- `Session.flush()` is needed before reading own pending writes within the same session (the first-level cache holds them until flush).

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `session.createQuery("FROM User WHERE name = '" + name + "'")` | HQL injection | Named parameters: `setParameter("name", name)` |
| Accessing a lazy collection after `session.close()` | `LazyInitializationException` | Initialize before close — `Hibernate.initialize(user.getOrders())` — or use `fetch="join"` in the mapping / HQL |
| `for (Order o : orders) { session.persist(o); }` for 1000+ rows | OutOfMemoryError; full first-level cache | Batch: `if (i % 50 == 0) { session.flush(); session.clear(); }` or use `StatelessSession` |
| `for (User u : users) { u.getOrders().size(); }` | N+1 query | Eager fetch via `fetch="join"` in `hbm.xml` or `JOIN FETCH` in HQL |
| Returning a managed entity after the session is closed | Lazy field access throws | Initialize required associations first, then `session.evict(e)`; or return a DTO projection |
| Sharing a `Session` across threads | Data corruption, `IllegalStateException` | Open a new session per thread |
| Catching `HibernateException` and continuing on the same session | Session state is undefined after any `HibernateException` | Always rollback + close the session, then open a new one for subsequent work |
| Using `@Transactional` annotation | No container interceptor wired — annotation is silently ignored | Use the explicit try/begin/commit/rollback pattern from Transaction Management above |
| `query.list()` to count rows | Loads all rows into memory just to call `.size()` | `query.uniqueResult()` with `SELECT count(*) ...` |
