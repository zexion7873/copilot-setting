---
description: 'Guidelines for structuring code and projects to maximize GitHub Copilot effectiveness through better context management'
applyTo: '**'
---

# Context Engineering

Principles for helping GitHub Copilot understand your codebase and provide better suggestions.

## Project Structure

- **Use descriptive file paths**: `src/auth/middleware.ts` > `src/utils/m.ts`. Copilot uses paths to infer intent.
- **Colocate related code**: Keep components, tests, types, and hooks together. One search pattern should find everything related.
- **Export public APIs from index files**: What's exported is the contract; what's not is internal. This helps Copilot understand boundaries.

## Code Patterns

- **Prefer explicit types over inference**: Type annotations are context. `public User findUserById(long id)` tells Copilot more than an untyped equivalent.
- **Use semantic names**: `activeAdultUsers` > `x`. Self-documenting code is AI-readable code.
- **Define constants**: `private static final int MAX_RETRY_ATTEMPTS = 3` > magic number `3`. Named values carry meaning.

## Context Hints

- **Add a COPILOT.md file**: Document architecture decisions, patterns, and conventions Copilot should follow.
- **Use strategic comments**: At the top of complex modules, briefly describe the flow or purpose.
- **Reference patterns explicitly**: "Follow the same pattern as `src/api/users.ts`" gives Copilot a concrete example.



