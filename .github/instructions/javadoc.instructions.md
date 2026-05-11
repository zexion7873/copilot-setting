---
description: 'Javadoc conventions for Java types and members — tags, formatting, when to document.'
applyTo: '**/*.java'
---

# Javadoc Conventions

Hard rules for documenting Java code. Public / protected APIs MUST be documented; private members SHOULD be when non-trivial.

## When to Document

- **Required**: public and protected types, methods, fields
- **Encouraged**: package-private and private members when complex, non-self-explanatory, or part of a key algorithm
- **Skip**: trivial getters / setters, overrides where `{@inheritDoc}` suffices and behavior is unchanged

## Summary Sentence

- The first sentence is the **summary**. Concise overview of what the method does. Ends with a period.
- Phrase as a third-person statement: `Returns the active user matching the given id.` not `Return the active user...`

## Standard Tags

| Tag | Use | Example |
|---|---|---|
| `@param` | Each method parameter; description starts lowercase, no trailing period | `@param userId the unique identifier of the user` |
| `@param <T>` | Type parameter on generic types / methods | `@param <T> the element type` |
| `@return` | Non-void return value | `@return the matching user, or {@code null} if not found` |
| `@throws` / `@exception` | Each declared / documented exception | `@throws IllegalArgumentException if {@code userId} is negative` |
| `@see` | Related types or members | `@see UserRepository#findById(long)` |
| `@since` | Version when introduced | `@since 1.4.0` |
| `@deprecated` | Mark deprecated; always provide alternative | `@deprecated since 2.0; use {@link #findActiveUserById(long)}` |
| `{@inheritDoc}` | Inherit from base class / interface; document only the differences if behavior changed | |

## Inline Formatting

- `{@code identifier}` — inline code, types, parameter names in prose
- `{@link Type#member}` — cross-reference to a navigable element
- `<pre>{@code ... }</pre>` — multi-line code blocks
- HTML allowed but minimize: `<p>` for paragraphs, `<ul><li>` for lists

## Anti-Patterns

- Restating the method signature in prose (`// Gets the user` above `getUser()`)
- Empty `@param` / `@return` lines
- Capitalized `@param` description ending in a period (style mismatch)
- `@author` / `@version` on every file — git already tracks this; reserve for stable public APIs
- Documenting `{@inheritDoc}` cases where behavior is identical (the inherited doc is enough)
