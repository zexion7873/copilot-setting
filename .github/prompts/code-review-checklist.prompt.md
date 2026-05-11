---
agent: 'agent'
description: 'Code review standards covering correctness, security, testing, performance, architecture, and documentation. Pairs with skills/code-review/SKILL.md (workflow / severity / verdict).'
---

# Code Review Standards

What to check by category during a code review. Workflow (scoping, reading order, verdict) lives in `skills/code-review/SKILL.md`.

## Severity Mapping

| Severity | Includes |
|---|---|
| CRITICAL | Security vulnerability, data corruption risk, crash on main path, breaking API change, secrets in source |
| WARNING | Performance (N+1, memory leak), missing error handling on non-critical path, test gap on changed code, deviation from established patterns |
| SUGGESTION | Naming, simplification, missing comment where WHY is non-obvious, minor style inconsistency |

## Correctness

- Code does what it claims; no off-by-one or null risks
- Edge cases handled (empty, boundary, error inputs)
- Error handling at the right layer; not swallowed in low-level code
- Fail fast — validate inputs at boundaries, trust internal calls

## Security

- No secrets, tokens, or PII in code, comments, or logs
- All user inputs validated and sanitized
- SQL: parameterized queries only; no string concatenation
- Auth + authz checks before accessing protected resources
- Crypto uses established libraries (no hand-rolled algorithms)
- Dependencies free of known CVEs

## Testing

- Critical paths and new functionality have tests
- Test names describe behavior + condition (`testX_shouldDoY_whenZ`)
- Tests are independent — no inter-test state
- Specific assertions (`assertEquals`, not `assertTrue(a.equals(b))`)
- Edge cases tested (null, empty, boundary)
- External dependencies mocked; domain logic not mocked

## Performance

- Appropriate algorithm complexity for the data size
- Caching used for expensive repeated computations
- Resources cleaned up (try-with-resources for `AutoCloseable`)
- Large result sets paginated or streamed
- SQL performance: apply rules from `instructions/sql-rules.instructions.md`

## Architecture

- Separation of concerns respected; layer boundaries clear
- Dependencies flow in one direction; no cycles
- Interfaces small and focused
- Established patterns followed; deviations justified

## Documentation

- Public APIs have Javadoc (purpose, params, returns, exceptions)
- Non-obvious logic has WHY comments — never WHAT comments
- README updated if setup or behavior changed
- Breaking changes documented

## Clean Code

- Names describe intent, not implementation
- Functions under ~30 lines; max 3 levels of nesting
- No duplication; no magic numbers / strings (use constants)
- No commented-out code
- No TODO without an associated ticket / owner

## Comment Format

```
[SEVERITY] Category — Title
  File: path/to/File.java#method:line
  Problem: <what is wrong, why it matters>
  Fix: <specific recommendation; show corrected code if helpful>
```
