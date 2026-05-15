---
description: 'Write self-explanatory code with minimal comments. Only comment WHY when non-obvious.'
applyTo: '**/*.{java,js,ts,py,cs}'
---

# Self-Explanatory Code & Commenting

Code should speak for itself. Comment only when **WHY** is non-obvious.

## Skip the Comment When

The code is self-explanatory, the comment restates WHAT the code does, the comment will rot, or the "comment" is dead code (delete it — git remembers).

## Write the Comment When

- Complex business logic — explain the rule, not the code
- Non-obvious algorithm choice — why this approach over alternatives
- Regex / cryptic format — what pattern this matches
- API constraints or workarounds — link the underlying issue

## Public API Documentation

Document public APIs with Javadoc / JSDoc / docstrings.
