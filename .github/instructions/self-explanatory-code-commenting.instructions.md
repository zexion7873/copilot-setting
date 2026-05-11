---
description: 'Write self-explanatory code with minimal comments. Only comment WHY when non-obvious. Applies to any language with comments.'
applyTo: '**/*.{java,js,ts,py,cs}'
---

# Self-Explanatory Code & Commenting

## Core Principle

Code should speak for itself. Comment only when **WHY** is non-obvious.

## Skip the Comment When

- The code is self-explanatory (a better name solves it — refactor instead)
- The comment restates WHAT the code does (`// increment counter` above `counter++`)
- The comment will rot (e.g., "Modified by John on 2023-01-15")
- The "comment" is a divider (`// ============ UTILS ============`)
- The "comment" is dead code (commented-out blocks — delete; git remembers)

## Write the Comment When

- **Complex business logic** — explain the rule, not the code
- **Non-obvious algorithm choice** — why Floyd-Warshall, not Dijkstra
- **Regex / cryptic format** — what pattern this matches
- **API constraints** — rate limits, required headers, gotchas
- **Configuration / magic constants** — source of the value, why this number
- **Workarounds** — link the underlying bug / PR

## Tag Conventions

When marking non-comment intent in code:

- `TODO` — future work; always pair with ticket / owner
- `FIXME` — known broken; describe the failure mode
- `HACK` — workaround; reference the underlying issue
- `NOTE` — surprising behavior or assumption
- `SECURITY` — security-sensitive code
- `PERF` — performance-sensitive code
- `DEPRECATED` — slated for removal; reference replacement

## Public API Documentation

Use Javadoc / JSDoc / docstrings on public APIs:

- One-line summary
- `@param`, `@returns`, `@throws` as applicable
- Usage example only when non-obvious

Avoid these on private helpers — the name should suffice.

## Checklist

- [ ] Could a better name remove the need for the comment? → refactor
- [ ] Does the comment explain WHY, not WHAT?
- [ ] Will the comment stay accurate as the code evolves?
