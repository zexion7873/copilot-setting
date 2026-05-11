---
description: 'JUnit 5 + Mockito conventions for Java tests — naming, structure, parameterization, assertions.'
applyTo: '**/*Test.java, **/*IT.java, **/test/**/*.java'
---

# JUnit 5 Conventions

Hard rules for tests written with JUnit 5 (Jupiter) + Mockito. Test design workflow lives in `skills/test-design/`. This file is the static convention layer.

## Project Setup

- Tests live under `src/test/java`
- Required dependencies: `junit-jupiter-api`, `junit-jupiter-engine`, `junit-jupiter-params` (parameterized), `mockito-core` + `mockito-junit-jupiter`
- Run via `mvn test` / `mvn verify` (the latter for `*IT.java` integration tests)

## Naming & Structure

- Test class: production class name + `Test` suffix (`Calculator` → `CalculatorTest`); integration tests use `IT` suffix (`PaymentFlowIT`)
- Test method name: `methodName_should_expectedBehavior_when_scenario` — readable in failure reports
- One behavior per test method; no `assertAll` over unrelated assertions
- Follow **Arrange-Act-Assert (AAA)** with blank lines between sections
- `@DisplayName` for human-readable names — especially for parameterized tests

## Lifecycle Annotations

| Annotation | Use |
|---|---|
| `@BeforeEach` / `@AfterEach` | Per-test setup / teardown |
| `@BeforeAll` / `@AfterAll` | Per-class; **must be `static`** |
| `@Nested` | Group related tests in inner classes |
| `@Tag("fast")` / `@Tag("integration")` | Categorize for selective execution |
| `@Disabled("reason")` | Skip with explicit reason — never skip silently |

## Parameterized Tests

- `@ParameterizedTest` mandatory; **never** loop with `@Test` over a list
- `@ValueSource` — single literal axis (strings, ints)
- `@CsvSource` — inline rows of multiple columns
- `@CsvFileSource` — large data sets from classpath CSV
- `@MethodSource` — when arguments need construction (use `Stream<Arguments>`)
- `@EnumSource` — exhaustive enum coverage
- `@NullSource` / `@EmptySource` / `@NullAndEmptySource` — boundary cases

## Assertions

- Static imports from `org.junit.jupiter.api.Assertions`
- Prefer **AssertJ** (`assertThat(...).isEqualTo(...)`) for chains and collection assertions — more readable failure messages
- `assertThrows` for expected exceptions; capture and assert on message / cause
- `assertAll` only to group **related** assertions on the same object (so first failure doesn't hide the rest)
- Always include a descriptive message when the assertion is non-obvious

## Mocking

- Mockito with `@ExtendWith(MockitoExtension.class)`
- `@Mock` for collaborators, `@InjectMocks` for the class under test
- Mock interfaces, not concrete classes (drives better design)
- `verify(mock).method()` for interaction tests; `times(n)` / `never()` explicit
- **Never mock value objects** (DTOs, entities) — construct real ones

## Independence

- Tests run in any order — no inter-test state leakage
- No shared mutable state between tests (`static` fields outside `@BeforeAll` are a smell)
- `@TestMethodOrder` only for documented exceptions (e.g. integration suite step ordering)

## Anti-Patterns

- Asserting against multiple unrelated behaviors in one test
- Using `Thread.sleep` for async — use `Awaitility` or test-controlled clocks
- Reaching into private state via reflection — refactor for testability instead
- Catching exceptions in test body just to call `fail(...)` — use `assertThrows`
- Test names like `test1`, `testFoo`, `shouldWork` — failure log becomes useless
