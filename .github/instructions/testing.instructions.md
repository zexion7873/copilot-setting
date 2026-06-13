---
description: 'Load when writing or reviewing a *Test.java / *IT.java file — JUnit 4 + Mockito + Spring Test 3.2. Triggers on: @RunWith(MockitoJUnitRunner / SpringJUnit4ClassRunner), org.junit.Test, @Before/@After, @Transactional auto-rollback. Not JUnit 5 (@BeforeEach/@ExtendWith) or @SpringBootTest. Defer non-test Java to java.instructions.md.'
applyTo: '**/*Test.java, **/*Tests.java, **/*IT.java'
---

# Testing Conventions

Test code is locked to the same stack as production. AI defaults to JUnit 5 + Spring Boot Test — both are wrong here. Java 8 language rules still apply: `instructions/java.instructions.md`.

## Framework Boundary (JUnit 5 / Spring Boot Forbidden)

- **JUnit 4** — `org.junit.Test`, `@Before` / `@After`, `Assert.assertEquals`. No `org.junit.jupiter.*`, no `@BeforeEach`, no `@ExtendWith`
- **Spring Test 3.2** — `@RunWith(SpringJUnit4ClassRunner.class)` + `@ContextConfiguration(locations = ...)`. No `@SpringBootTest`, no `@ExtendWith(SpringExtension.class)`, no `@WebMvcTest`
- **Mockito** — `@RunWith(MockitoJUnitRunner.class)` or `MockitoAnnotations.initMocks(this)`. No `@ExtendWith(MockitoExtension.class)`
- Assertions: JUnit `Assert.*` or Hamcrest `assertThat`; AssertJ only if already on the classpath

## Structure

- One behavior per test method; name `methodName_condition_expectedResult`
- Arrange–Act–Assert, visually separated
- No interdependence — each test runs in isolation, in any order
- No logic (loops / conditionals) inside a test — if you need it, the test is too broad

## Spring Integration Tests

- `@ContextConfiguration` against a test-scoped XML context, not production beans
- `@Transactional` on a test class for auto-rollback is acceptable — this is test-only and does NOT violate the production `<tx:advice>`-only rule in `instructions/spring-hibernate.instructions.md`
- Never hit a real external service — stub at the boundary

## Data & Mocks

- Mock collaborators at the layer boundary (mock the DAO in service tests)
- No shared mutable static fixtures across test classes
- Deterministic: no `new Date()` / unseeded random — inject a fixed clock or seed

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `import org.junit.jupiter.api.Test` | JUnit 5 — not this project's stack | `import org.junit.Test` (JUnit 4) |
| `@SpringBootTest` | No Spring Boot in this project | `@RunWith(SpringJUnit4ClassRunner.class)` + `@ContextConfiguration` |
| `@BeforeEach` / `@AfterEach` | JUnit 5 lifecycle | `@Before` / `@After` (JUnit 4) |
| `@ExtendWith(MockitoExtension.class)` | JUnit 5 extension model | `@RunWith(MockitoJUnitRunner.class)` |
| One test depending on another's side effects | Order-dependent, flaky | Isolate; each test builds its own fixture |
| `Thread.sleep()` to wait for async work | Flaky and slow | Await a condition or inject a synchronous executor |
