---
description: 'Load when writing or reviewing a *Test.java / *IT.java file — JUnit 4 + Mockito + Spring Test 3.2. Triggers on: @RunWith(MockitoJUnitRunner / SpringJUnit4ClassRunner), org.junit.Test, @Before/@After, @Transactional auto-rollback. Not JUnit 5 (@BeforeEach/@ExtendWith) or @SpringBootTest. Defer non-test Java to java.instructions.md.'
applyTo: '**/Test*.java, **/*Test.java, **/*Tests.java, **/*TestCase.java, **/IT*.java, **/*IT.java, **/*ITCase.java'
---

# Testing Conventions

Java 8 language rules apply: `instructions/java.instructions.md`.

## Framework Boundary (JUnit 5 / Spring Boot Forbidden)

- **JUnit 4** — `org.junit.Test`, `@Before` / `@After`, `Assert.assertEquals`. No `org.junit.jupiter.*` / `@BeforeEach` / `@ExtendWith`
- **Spring Test 3.2** — `@RunWith(SpringJUnit4ClassRunner.class)` + `@ContextConfiguration`. No `@SpringBootTest` / `@WebMvcTest` / `@ExtendWith(SpringExtension.class)`
- **Mockito** — `@RunWith(MockitoJUnitRunner.class)` or `MockitoAnnotations.initMocks(this)`. No `@ExtendWith(MockitoExtension.class)`
- Assertions: `Assert.*` or Hamcrest `assertThat`; AssertJ only if already on the classpath

## Structure

- One behavior per test; name `methodName_condition_expectedResult`; Arrange–Act–Assert, visually separated
- No interdependence (isolated, any order); no logic (loops / conditionals) inside a test

## Integration Tests

- `@ContextConfiguration` against a test-scoped XML context, not production beans
- Test-class `@Transactional` auto-rollback is sanctioned — test-only; does NOT violate the production `<tx:advice>`-only rule (`instructions/spring-hibernate.instructions.md`)

## Data & Mocks

- Mock collaborators at the layer boundary (DAO in service tests); no shared mutable static fixtures
- Never hit a real external service — stub at the boundary
- Deterministic: no `new Date()` / unseeded random — inject a fixed clock or seed
- Never `Thread.sleep()` to wait for async — flaky and slow; await a condition or inject a synchronous executor
