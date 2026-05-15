---
description: 'Hibernate 4.x conventions — native Session API, hbm.xml mappings, session lifecycle, transaction patterns, and Hibernate-specific anti-patterns.'
applyTo: '**/*.java, **/*.hbm.xml'
---

# Hibernate Conventions

Hard rules for Hibernate 4.x using native Session API plus `hbm.xml` mappings. Cross-references: `instructions/sql-rules.instructions.md` for raw JDBC fallback paths, `instructions/error-handling.instructions.md` for DAO-layer exception translation, `instructions/xml.instructions.md` for general XML conventions that apply to `hbm.xml` files.

## API Style

- Use **Hibernate native Session**, not JPA `EntityManager`. `SessionFactory` is a Spring-managed bean (configured via `LocalSessionFactoryBean`) — inject it into DAOs.
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

## Query Patterns

| Use case | API |
|---|---|
| Static query with known fields | HQL — `session.createQuery("FROM User u WHERE u.email = :email")` |
| Dynamic filters (search forms) | Criteria — `session.createCriteria(User.class).add(Restrictions.eq(...))` |
| Complex aggregation / DB-specific functions | Native SQL — `session.createSQLQuery(...).addEntity(User.class)` |
| Batch insert / update | `StatelessSession`, or flush + clear every 50 rows |

- Always use **named parameters** (`:paramName`). Never string concatenation — same rule as `instructions/sql-rules.instructions.md`, and also applies to HQL.
- Pagination: `query.setFirstResult(offset).setMaxResults(limit)`. Avoid large offsets — prefer keyset pagination on indexed columns.

## Session Lifecycle

- DAOs obtain the session via `sessionFactory.getCurrentSession()`. Spring's `HibernateTransactionManager` binds a session to the active transaction and returns the same instance for the duration of that transaction.
- DAOs MUST NOT call `openSession()`, `close()`, or `beginTransaction()` — Spring owns the lifecycle.
- `openSession()` is acceptable only outside any Spring-managed code path (e.g. main-method utilities, jobs that run before the Spring context is ready). When used, pair it with `finally { session.close(); }`.
- The session is bound to the transaction's thread; never pass it to a separate thread (`ExecutorService`, async callback) — that thread must enter its own transactional boundary and call `getCurrentSession()` again.
- A transaction-bound session is implicitly flushed and closed when the surrounding service method commits — no explicit `flush()` or `close()` in DAOs.

## Transaction Management

The codebase uses Spring's declarative transaction management — no Spring Boot, no annotations.

- `transactionManager` bean — `org.springframework.orm.hibernate4.HibernateTransactionManager`, wired to the `SessionFactory`.
- `<tx:advice id="txAdvice" transaction-manager="transactionManager">` with `<tx:method>` entries controls propagation, isolation, `read-only`, and `rollback-for` per method-name pattern.
- `<aop:config>` pointcut wires the advice to the **service layer** (e.g. `execution(* com.example.service..*Service.*(..))`). Matching methods become transactional automatically.

Rules for new code:

- Transactions live in the **service layer**, not in DAOs. Services compose DAO calls; the AOP advice wraps the whole service method.
- DAOs are pure data access — no transaction code, no session lifecycle code, no try/catch around session work.
- Do NOT use `@Transactional` annotation — this project uses XML AOP exclusively. Mixing styles makes the actual transaction boundary unobvious.
- Do NOT call `session.beginTransaction()` / `commit()` / `rollback()` manually inside an advised method — it fights Spring's transaction synchronization and can corrupt the session.
- **Read-only methods** — declare them under `<tx:advice>` with `read-only="true"` (e.g. `get*`, `find*`, `list*`, `count*` patterns). Sets Hibernate flush mode to `MANUAL` and enables DB-side read optimizations.
- **Rollback rules** — Spring rolls back on `RuntimeException` / `Error` only. If a service method throws a checked exception that should trigger rollback, add `rollback-for="com.example.SomeCheckedException"` on the matching `<tx:method>`.
- **Self-invocation bypasses the proxy** — calling `this.someAdvisedMethod()` from within the same class skips AOP and inherits the caller's transaction (or none). To enter a new transaction, the call must go through an injected proxy reference (typically a separate service bean).

Example shape — transaction is invisible because AOP wraps it:

```java
public class OrderService {
    private final OrderDao orderDao;
    private final InventoryDao inventoryDao;

    public void placeOrder(Order order) {
        // Both DAO calls share the same Session and Transaction,
        // managed by Spring. No try/commit/rollback here.
        inventoryDao.decrement(order.getItems());
        orderDao.insert(order);
    }
}
```

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
| Lazy collection accessed by caller (controller / JSP) after the service method returns | Session is closed at transaction boundary → `LazyInitializationException` | Initialize associations inside the service — `Hibernate.initialize(user.getOrders())` or `JOIN FETCH` — or return a DTO projection |
| `for (Order o : orders) { session.persist(o); }` for 1000+ rows | OutOfMemoryError; full first-level cache | Batch: `if (i % 50 == 0) { session.flush(); session.clear(); }` or use `StatelessSession` |
| `for (User u : users) { u.getOrders().size(); }` | N+1 query | Eager fetch via `fetch="join"` in `hbm.xml` or `JOIN FETCH` in HQL |
| DAO calls `sessionFactory.openSession()` | Creates a session unrelated to the active transaction → writes happen outside the tx boundary | Always use `getCurrentSession()`; Spring owns the lifecycle |
| Manual `session.beginTransaction()` / `commit()` / `rollback()` inside an advised service or DAO | Conflicts with Spring's transaction synchronization; commits may go to the wrong layer | Let `<tx:advice>` handle it — remove the manual transaction calls |
| `this.someAdvisedMethod()` to start a new transaction | Self-invocation bypasses the AOP proxy — second method inherits caller's transaction or has none | Inject the proxied bean (or split into another service) and call through the proxy reference |
| Service throws a checked exception and expects rollback | Spring rolls back only on `RuntimeException` / `Error` by default — checked exception commits | Add `rollback-for="com.example.SomeCheckedException"` on the matching `<tx:method>` |
| Adding `@Transactional` annotation alongside XML `<tx:advice>` | Mixed styles → actual transaction boundary becomes invisible to readers | Pick one — this project standardizes on XML `<tx:advice>` only |
| Sharing a `Session` across threads (passing into `ExecutorService` etc.) | Session is not thread-safe; bound to one transaction context | The new thread must enter its own transactional boundary and call `getCurrentSession()` |
| Catching `HibernateException` inside a service and continuing | Session state is undefined after any `HibernateException`; rollback is also needed | Let it propagate — Spring's advice will roll back; do not swallow |
| `query.list()` to count rows | Loads all rows into memory just to call `.size()` | `query.uniqueResult()` with `SELECT count(*) ...` |
