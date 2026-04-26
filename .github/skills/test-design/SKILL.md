---
name: test-design
description: 'Structured test case design workflow for systematic test coverage. Use when user asks to design tests, create test cases, plan test coverage, or mentions "/test-design". Walks through: code analysis, test boundary identification, case design by category (happy path, edge, error, boundary, integration, security), JUnit 5 implementation with data-driven patterns, and coverage gap analysis. Designed for @test-designer agent but usable by any agent writing tests.'
license: MIT
allowed-tools: ['search', 'edit', 'read/problems']
---

# Test Design — Executable Workflow

## Overview

A structured test design process that replaces "write tests until it feels covered" with systematic boundary analysis and category-driven case generation. This skill defines HOW to design tests, not WHAT the agent persona is (that's in the agent file).

## When to Use

- User asks to design or write tests for a method, class, or feature
- Reviewing test coverage gaps in existing code
- Starting a new feature and planning tests upfront (TDD)
- User asks "what should I test here", "write test cases", "cover this with tests"
- User invokes `/test-design`

---

## Phase 1 — Analyze the Code Under Test

Before writing a single test, understand what you're testing.

### 1.1 Read the Signature and Contract

```
For each method under test, capture:
  Method name:     [name]
  Return type:     [type — or void]
  Parameters:      [name: type for each]
  Throws:          [declared exceptions]
  Visibility:      [public / package-private]
  Static/instance: [static / instance]
```

### 1.2 Map All Code Paths

Trace every branch in the method body:

```
Code path inventory:
  □ if/else branches — list each condition
  □ switch cases — list each case + default
  □ try/catch blocks — list each exception type caught
  □ early returns — list each guard clause
  □ loops — list entry condition and exit condition
  □ Optional.map / filter / orElse chains
  □ Stream pipeline stages
```

### 1.3 Identify Inputs, Outputs, and Side Effects

```
INPUTS:
  Direct params: [list]
  Implicit state: [fields read from this / static state]
  External reads: [DB queries, file reads, cache lookups]

OUTPUTS:
  Return value: [what it returns and when]
  Thrown exceptions: [which exceptions, under what conditions]

SIDE EFFECTS:
  Writes: [DB inserts/updates, file writes, cache puts]
  Calls: [external service calls, event publishing]
  State mutations: [fields modified on this or collaborators]
```

### 1.4 Map Dependencies to Mock

```
Dependency inventory:
  [ClassName fieldName] — mock with @Mock
  [ClassName fieldName] — mock with @Mock
  ...

Inject into: [ClassUnderTest] with @InjectMocks
```

---

## Phase 2 — Identify Test Boundaries

Systematic boundary identification prevents the most common coverage gaps.

### 2.1 Null and Empty Inputs

```
For each parameter:
  □ null — what happens?
  □ empty string "" — valid or rejected?
  □ blank string "   " — treated as empty or valid?
  □ empty collection [] — handled or throws?
  □ Optional.empty() — if parameter is Optional
```

### 2.2 Numeric Boundaries

```
For each numeric parameter or field:
  □ 0 — zero case
  □ -1 — negative (if domain allows)
  □ Integer.MIN_VALUE / Long.MIN_VALUE — underflow
  □ Integer.MAX_VALUE / Long.MAX_VALUE — overflow
  □ Precision: 0.1 + 0.2 != 0.3 for doubles
  □ Domain minimum (e.g., age >= 0, price > 0)
  □ Domain maximum (e.g., quantity <= 999)
  □ One below minimum (invalid)
  □ One above maximum (invalid)
```

### 2.3 Collection Sizes

```
For each collection parameter or return:
  □ Size 0 — empty collection
  □ Size 1 — single element
  □ Size 2 — two elements (tests ordering, pairing logic)
  □ Size N — typical case
  □ Size MAX — performance / memory boundary
  □ null vs empty — are they treated the same?
```

### 2.4 String Edge Cases

```
For each String parameter:
  □ null
  □ "" (empty)
  □ " " (whitespace only)
  □ Single character
  □ Max allowed length
  □ Max + 1 (over limit)
  □ Special characters: !@#$%^&*()
  □ Unicode: 中文, emoji, RTL characters
  □ SQL metacharacters: ' " ; -- (injection probe)
  □ HTML metacharacters: < > & " ' (XSS probe)
```

### 2.5 Date and Time Edge Cases

```
For date/time parameters:
  □ null
  □ Epoch (1970-01-01)
  □ Leap year date (Feb 29)
  □ Non-leap year Feb 29 (invalid)
  □ End of month (Jan 31, Feb 28/29, etc.)
  □ End of year (Dec 31)
  □ Timezone boundary (midnight UTC vs local)
  □ DST transition dates
  □ Far future / far past dates
```

### 2.6 Concurrency Boundaries (if applicable)

```
If the method accesses shared state:
  □ Concurrent reads — thread-safe?
  □ Concurrent writes — race condition?
  □ Read-write interleaving — stale data?
  □ Double-checked locking — correct?
```

---

## Phase 3 — Design Test Cases by Category

Use this table to generate test cases systematically. Fill one row per test case.

### Output Table Format

```
| # | Category | Test Name | Input | Expected Result | Priority |
|---|----------|-----------|-------|-----------------|----------|
```

### Category Definitions

**Happy Path (P0)** — The method works correctly with valid, typical input.

```
Goal: Prove the core contract works.
One test per distinct "normal" scenario.
Example row:
| 1 | Happy Path | testFindUser_shouldReturnUser_whenIdExists | userId=42 | User{id=42, name="Alice"} | P0 |
```

**Alternative Paths (P0-P1)** — Valid inputs that trigger different branches.

```
Goal: Cover every if/else branch with a valid input.
One test per branch that changes the return value or behavior.
Example row:
| 2 | Alternative Path | testFindUser_shouldReturnEmpty_whenUserInactive | userId=99 (inactive) | Optional.empty() | P0 |
```

**Error Paths (P1)** — Expected exceptions and error handling.

```
Goal: Verify the method throws the right exception with the right message.
One test per declared exception type.
Example row:
| 3 | Error Path | testFindUser_shouldThrowNotFound_whenIdMissing | userId=-1 | throws UserNotFoundException | P1 |
```

**Boundary Values (P1)** — Edge cases from Phase 2.

```
Goal: Verify behavior at the limits of valid and invalid input.
One test per boundary identified in Phase 2.
Example row:
| 4 | Boundary | testCreateUser_shouldRejectName_whenNameExceedsMaxLength | name=256 chars | throws ValidationException | P1 |
```

**Integration (P2)** — Interactions with external systems.

```
Goal: Verify the method correctly delegates to and handles responses from dependencies.
One test per dependency interaction type (success, failure, timeout).
Example row:
| 5 | Integration | testFindUser_shouldReturnCached_whenCacheHit | userId=42, cache populated | User from cache, no DB call | P2 |
```

**Security (P2)** — Injection and unauthorized access probes.

```
Goal: Verify the method rejects or sanitizes malicious input.
One test per attack vector identified in Phase 2.
Example row:
| 6 | Security | testFindUser_shouldRejectSqlInjection_whenIdContainsSql | userId="1 OR 1=1" | throws ValidationException | P2 |
```

---

## Phase 4 — Implement Tests (JUnit 5)

### 4.1 Test Class Structure

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private CacheService cacheService;

    @InjectMocks
    private UserService userService;

    // Happy path and alternative paths
    @Nested
    class FindUser {

        @Test
        void testFindUser_shouldReturnUser_whenIdExists() {
            // Arrange
            long userId = 42L;
            User expected = new User(userId, "Alice");
            when(userRepository.findById(userId)).thenReturn(Optional.of(expected));

            // Act
            User actual = userService.findUser(userId);

            // Assert
            assertAll(
                () -> assertEquals(expected.getId(), actual.getId()),
                () -> assertEquals(expected.getName(), actual.getName())
            );
            verify(userRepository).findById(userId);
        }

        @Test
        void testFindUser_shouldThrowNotFound_whenIdMissing() {
            // Arrange
            long userId = -1L;
            when(userRepository.findById(userId)).thenReturn(Optional.empty());

            // Act & Assert
            UserNotFoundException ex = assertThrows(
                UserNotFoundException.class,
                () -> userService.findUser(userId)
            );
            assertTrue(ex.getMessage().contains(String.valueOf(userId)));
        }
    }
}
```

### 4.2 Naming Convention

```
Pattern: test[MethodName]_should[ExpectedBehavior]_when[Condition]

Examples:
  testCreateUser_shouldReturnId_whenInputIsValid
  testCreateUser_shouldThrowValidation_whenNameIsNull
  testCreateUser_shouldThrowValidation_whenNameExceedsMaxLength
  testFindActiveUsers_shouldReturnEmpty_whenNoActiveUsersExist
  testCalculateDiscount_shouldApplyMaxDiscount_whenQuantityExceedsThreshold
```

### 4.3 Parameterized Tests for Boundary Values

Use `@CsvSource` for inline data:

```java
@ParameterizedTest(name = "name=''{0}'' should be rejected")
@CsvSource({
    ",",                          // null (empty CSV cell)
    "''",                         // empty string
    "'   '",                      // whitespace only
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" // 256 chars
})
void testCreateUser_shouldThrowValidation_whenNameIsInvalid(String name) {
    assertThrows(
        ValidationException.class,
        () -> userService.createUser(name, "test@example.com")
    );
}
```

Use `@MethodSource` for complex objects:

```java
@ParameterizedTest
@MethodSource("invalidUserInputs")
void testCreateUser_shouldThrowValidation_whenInputIsInvalid(String name, String email, String reason) {
    assertThrows(
        ValidationException.class,
        () -> userService.createUser(name, email),
        reason
    );
}

static Stream<Arguments> invalidUserInputs() {
    return Stream.of(
        Arguments.of(null, "test@example.com", "null name"),
        Arguments.of("Alice", null, "null email"),
        Arguments.of("Alice", "not-an-email", "malformed email"),
        Arguments.of("Alice", "", "empty email")
    );
}
```

### 4.4 Nested Classes for Grouping

```java
class OrderServiceTest {

    @Nested
    @DisplayName("placeOrder")
    class PlaceOrder {

        @Nested
        @DisplayName("happy path")
        class HappyPath {
            @Test
            void testPlaceOrder_shouldCreateOrder_whenStockAvailable() { ... }
        }

        @Nested
        @DisplayName("error paths")
        class ErrorPaths {
            @Test
            void testPlaceOrder_shouldThrowOutOfStock_whenQuantityExceedsStock() { ... }

            @Test
            void testPlaceOrder_shouldThrowInvalidInput_whenQuantityIsZero() { ... }
        }
    }
}
```

### 4.5 Mockito Patterns

```java
// Stub a return value
when(repository.findById(42L)).thenReturn(Optional.of(user));

// Stub to throw
when(repository.save(any())).thenThrow(new DataAccessException("DB down") {});

// Verify a call happened
verify(repository).save(argThat(u -> u.getName().equals("Alice")));

// Verify a call did NOT happen
verify(cacheService, never()).put(any(), any());

// Verify call count
verify(repository, times(1)).findById(anyLong());

// Capture arguments for detailed assertion
ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
verify(repository).save(captor.capture());
assertEquals("Alice", captor.getValue().getName());
```

### 4.6 Exception Testing

```java
// Assert exception type
assertThrows(UserNotFoundException.class, () -> service.findUser(-1L));

// Assert exception message
UserNotFoundException ex = assertThrows(
    UserNotFoundException.class,
    () -> service.findUser(-1L)
);
assertEquals("User not found: -1", ex.getMessage());

// Assert no exception thrown
assertDoesNotThrow(() -> service.findUser(42L));
```

---

## Phase 5 — Coverage Gap Analysis

After writing tests, verify completeness with this checklist.

### 5.1 Branch Coverage Checklist

```
For each if/else in the method:
  □ True branch tested?
  □ False branch tested?
  □ Null-check branch tested (both null and non-null)?

For each switch:
  □ Each case tested?
  □ Default case tested?

For each try/catch:
  □ Happy path (no exception) tested?
  □ Each caught exception type tested?
  □ Finally block behavior tested (if applicable)?

For each early return / guard clause:
  □ Condition that triggers early return tested?
  □ Condition that passes through tested?
```

### 5.2 Dependency Interaction Checklist

```
For each mocked dependency:
  □ Success response tested?
  □ Empty/null response tested?
  □ Exception response tested?
  □ Verify called with correct arguments?
  □ Verify NOT called when it shouldn't be?
```

### 5.3 State Mutation Checklist

```
If the method modifies state:
  □ State before and after verified?
  □ Partial failure leaves state consistent?
  □ Idempotency verified (if applicable)?
```

### 5.4 Mutation Testing Considerations

Mutation testing tools (like PIT) introduce small code changes and check if tests catch them. Design tests to catch these common mutations:

```
Common mutations to guard against:
  □ Boundary condition flipped: > changed to >= (test the exact boundary value)
  □ Return value changed: return true changed to return false (assert the exact value)
  □ Condition negated: if (x != null) changed to if (x == null) (test both branches)
  □ Method call removed: verify() calls in tests catch this
  □ Arithmetic operator changed: + to - (assert exact numeric result)
```

---

## Common Java 8 Test Patterns

### Testing Optional

```java
// Method returns Optional<User>
Optional<User> result = service.findUser(42L);

// Assert present
assertTrue(result.isPresent());
assertEquals("Alice", result.get().getName());

// Assert empty
assertFalse(result.isPresent());

// Or with assertAll
assertAll(
    () -> assertTrue(result.isPresent()),
    () -> assertEquals("Alice", result.map(User::getName).orElse(null))
);
```

### Testing Stream Operations

```java
// Method returns a filtered/mapped list
List<String> activeNames = service.getActiveUserNames();

// Assert contents (order-independent)
assertThat(activeNames).containsExactlyInAnyOrder("Alice", "Bob");

// Assert with JUnit 5 only (no AssertJ)
assertEquals(2, activeNames.size());
assertTrue(activeNames.contains("Alice"));
assertTrue(activeNames.contains("Bob"));

// Assert stream produces correct count
assertEquals(3, service.countActiveUsers());
```

### Testing Functional Interfaces and Lambdas

```java
// If the method accepts a Predicate or Function, test with concrete lambdas
List<User> filtered = service.filterUsers(user -> user.getAge() >= 18);
assertTrue(filtered.stream().allMatch(u -> u.getAge() >= 18));

// If the method returns a Comparator
Comparator<User> byName = service.getNameComparator();
List<User> users = Arrays.asList(new User("Charlie"), new User("Alice"), new User("Bob"));
users.sort(byName);
assertEquals("Alice", users.get(0).getName());
```

### Testing java.time (Java 8 Date/Time API)

```java
// Inject a fixed clock for deterministic time-based tests
Clock fixedClock = Clock.fixed(
    Instant.parse("2024-01-15T10:00:00Z"),
    ZoneId.of("UTC")
);
// Pass clock to service constructor or setter
UserService service = new UserService(repository, fixedClock);

// Test leap year handling
LocalDate leapDay = LocalDate.of(2024, 2, 29);
assertTrue(service.isValidBirthDate(leapDay));

LocalDate nonLeapDay = LocalDate.of(2023, 2, 29); // throws DateTimeException
// Test that your code handles this gracefully
```

### Testing Collections (Unmodifiable, Concurrent)

```java
// Verify returned collection is unmodifiable
List<User> result = service.getUsers();
assertThrows(UnsupportedOperationException.class, () -> result.add(new User("Hacker")));

// Verify returned collection is a defensive copy (mutation doesn't affect internal state)
List<User> copy1 = service.getUsers();
List<User> copy2 = service.getUsers();
assertNotSame(copy1, copy2);
```

---

## Test Anti-Patterns

Avoid these patterns — they produce tests that pass but don't actually protect you.

| Anti-Pattern | Why It Fails | Do This Instead |
|-------------|-------------|-----------------|
| Testing implementation, not behavior | Test breaks on refactor even when behavior is correct | Assert on return values and side effects, not on internal method calls |
| Overly complex test setup (50+ lines of arrange) | Hard to understand what's being tested | Extract setup to helper methods or `@BeforeEach`; if setup is huge, the class under test may need splitting |
| Tests that depend on execution order | Brittle — fails when test runner changes order | Each test must set up its own state; never rely on state from a previous test |
| Ignoring flaky tests | Flaky tests erode trust in the suite | Fix or delete flaky tests immediately; never use `@Disabled` as a permanent solution |
| No assertion (test that can never fail) | Gives false confidence — the test always passes | Every test must have at least one `assert*` or `verify()` call |
| Testing private methods directly | Couples tests to implementation details | Test private behavior through the public API that exercises it |
| Mocking the class under test | You're testing the mock, not the real code | Only mock dependencies, never the class being tested |
| `assertTrue(result.equals(expected))` | Failure message is useless: "expected true but was false" | Use `assertEquals(expected, result)` for a useful diff in the failure message |

---

## Quick Test Design Checklist

For smaller methods, use this condensed checklist before writing any code:

```
□ What does this method do when everything is valid? (happy path)
□ What happens with null inputs?
□ What happens at the minimum valid value?
□ What happens at the maximum valid value?
□ What happens one step beyond the boundary?
□ What exceptions should it throw, and when?
□ What dependencies does it call, and do I verify them?
□ Does it return a collection? Test size 0, 1, and many.
□ Does it modify state? Verify before and after.
□ Is there a security concern? Test injection and unauthorized access.
```
