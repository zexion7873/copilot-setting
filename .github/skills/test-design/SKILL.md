---
name: test-design
description: 'Use when user asks to design tests, write test cases, plan test coverage, or identify what to test. Also triggers on: 寫測試, 測試案例, 要測什麼, 補 test, 測試覆蓋率. Produces JUnit 5 tests covering happy path, edge cases, error handling, and boundary conditions. Do NOT use for running existing tests, fixing test infrastructure, or debugging test failures — prefer debug skill for that.'
context: fork
---

# Test Design — Workflow

Process for designing tests systematically. Targets JUnit 5 + Mockito. This file defines HOW to design, not coding standards.

## Phase 1 — Analyze the Code Under Test

For each method capture:

- Signature: name, return type, parameters, declared exceptions, visibility
- All branches: if/else, switch cases, try/catch, early returns, loops, Optional chains, Stream stages
- Inputs: direct params, fields read, external reads (DB, file, cache)
- Outputs: return values, thrown exceptions
- Side effects: DB writes, file writes, cache puts, external calls, state mutations
- Dependencies to mock: list each one

## Phase 2 — Identify Boundaries

Run every parameter through these axes.

### Null / Empty
- `null` — accepted or rejected?
- `""` empty string — same as null?
- `"   "` blank — same as empty?
- `[]` empty collection — same as null?
- `Optional.empty()` — for Optional params

### Numeric
- `0`, `-1`
- `Integer.MIN_VALUE` / `MAX_VALUE` (under/overflow)
- Domain min / max
- One below min, one above max (invalid)
- Doubles: precision (`0.1 + 0.2 != 0.3`)

### Collection sizes
- 0, 1, 2 (ordering boundary), N (typical), MAX (perf boundary)
- `null` vs `[]` — distinguished?

### Strings
- `null`, `""`, `" "`, single char, max length, max+1
- Special chars: `!@#$%^&*()`
- Unicode: 中文, emoji, RTL
- SQL probe: `' " ; --`
- HTML probe: `< > & " '`

### Dates / Times
- `null`, epoch, leap year Feb 29, non-leap Feb 29 (invalid)
- Month/year end, midnight UTC vs local, DST transition

### Concurrency (if shared state)
- Concurrent read, concurrent write, read-write interleave

## Phase 3 — Design Cases by Category

One row per test:

```
| # | Category | Test Name | Input | Expected | Priority |
```

Categories:

- **Happy Path (P0)** — One per distinct normal scenario
- **Alternative Paths (P0-P1)** — One per branch that changes behavior
- **Error Paths (P1)** — One per declared exception type
- **Boundary Values (P1)** — One per boundary identified in Phase 2
- **Integration (P2)** — One per dependency interaction (success/failure/timeout)
- **Security (P2)** — One per attack vector (injection, auth bypass)

## Phase 4 — Implement (JUnit 5 + Mockito)

Naming: `test<MethodName>_should<ExpectedBehavior>_when<Condition>`

Example: `testCreateUser_shouldThrowValidation_whenNameExceedsMaxLength`

Skeleton:

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    @Mock private UserRepository userRepository;
    @InjectMocks private UserService userService;

    @Nested
    class FindUser {
        @Test
        void testFindUser_shouldReturnUser_whenIdExists() {
            when(userRepository.findById(42L)).thenReturn(Optional.of(new User(42L, "Alice")));

            User actual = userService.findUser(42L);

            assertEquals("Alice", actual.getName());
            verify(userRepository).findById(42L);
        }
    }
}
```

Use `@ParameterizedTest` with `@CsvSource` for inline data or `@MethodSource` for complex objects. Group by scenario with `@Nested`.

Mockito reminders:

- `verify(x, never()).method()` to assert NOT called
- `ArgumentCaptor` for detailed argument assertions
- Mock only dependencies, never the class under test

Time-dependent tests: inject a fixed `Clock` (`Clock.fixed(Instant.parse(...), ZoneId.of("UTC"))`); never use `Instant.now()` in production code without injection.

## Phase 5 — Coverage Gap Audit

Branch coverage:

- Each `if/else`: both branches tested
- Each `switch`: every case + default
- Each `try/catch`: happy path + each caught exception type
- Each guard / early return: triggered + pass-through

Dependency interactions:

- Success response
- Empty / null response
- Exception response
- `verify()` called with correct args
- `verify(_, never())` when it shouldn't be called

Make tests resilient to mutation testing:

- Boundary flip (`>` vs `>=`) → test the exact boundary
- Return value flip → assert exact value, not truthiness
- Condition negation → test both branches
- Removed method call → use `verify()`
- Arithmetic operator swap → assert exact result

## Test Anti-Patterns

| Pattern | Why bad | Do instead |
|---|---|---|
| Testing implementation not behavior | Breaks on refactor | Assert returns + side effects, not call sequence |
| 50+ lines of setup | Unreadable | Extract to `@BeforeEach` / helpers; if huge, split the class |
| Order-dependent tests | Flaky | Each test sets up own state |
| `@Disabled` left long-term | Hides decay | Fix or delete |
| Test with no `assert*` | Always passes | Every test asserts at least once |
| Testing private methods directly | Couples to internals | Test through public API |
| Mocking the class under test | Tests the mock | Only mock dependencies |
| `assertTrue(a.equals(b))` | Useless failure msg | `assertEquals(b, a)` |

## Quick Checklist (small methods)

- What does it do with valid input? (happy path)
- What with `null`?
- What at min / max valid value?
- What one step past the boundary?
- What exceptions, when?
- What dependencies, do I `verify()` them?
- Collection return → test size 0, 1, many
- State mutation → verify before / after
- Security concern → test injection + unauthorized access
