---
agent: 'agent'
description: 'Code review severity model and category checklist. Pairs with skills/code-review/SKILL.md (workflow).'
---

# Code Review Checklist

Severity model and per-category checks for the `code-review` skill. Workflow: `skills/code-review/SKILL.md`.

## Severity Model

| Severity | Definition | Action |
|---|---|---|
| 🔴 CRITICAL | Security vuln, data loss, crash in production | Must fix before merge |
| 🟠 MAJOR | Bug, performance issue, convention violation | Should fix |
| 🟡 MINOR | Style, naming, minor improvement | Nice to fix |
| ⚪ NIT | Preference, trivial | Optional |

## Category Checks

### Correctness

- Logic errors, off-by-one, null handling
- Edge cases: empty collections, zero values, null inputs
- Concurrency: shared mutable state, thread safety
- Resource leaks: unclosed connections, streams

### Security

- SQL injection: all queries parameterized?
- XSS: all JSP output encoded?
- Auth: access control on every endpoint?
- Secrets: no hardcoded credentials?

### Performance

- N+1 queries (SQL inside loops)?
- `SELECT *` or missing indexes?
- Unbounded result sets without pagination?
- Expensive operations in hot paths?

### Convention Compliance

- Java 8 only (no `var`, `List.of()`, records)?
- Hibernate: `getCurrentSession()`, hbm.xml, no JPA annotations?
- Transactions: `<tx:advice>` only, no `@Transactional`?
- Logging: SLF4J parameterized, correct severity levels?
- Error handling: proper exception hierarchy and translation?

### Maintainability

- Clear naming (methods, variables, classes)?
- No duplicated code?
- Methods ≤30 lines of logic?
- Comments explain WHY, not WHAT?

## Comment Format

```
[SEVERITY] Category — description
Location: file:line
Suggestion: <specific fix>
```
