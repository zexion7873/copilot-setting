---
description: 'Markdown formatting aligned to the CommonMark specification (0.31.2)'
applyTo: '**/*.md'
---

# CommonMark Markdown

Apply these rules per the [CommonMark spec 0.31.2](https://spec.commonmark.org/0.31.2/) when writing or reviewing `.md` files. Do not download the spec.

## Key Rules

- **ATX headings**: 1–6 `#` followed by a space. Use ATX (`#`) over setext (`===`/`---`) for consistency.
- **Fenced code blocks**: 3+ backticks or tildes (don't mix). Always specify a language identifier. Closing fence must match the opening character and count.
- **Indented code blocks**: 4+ spaces indent. Must be preceded by a blank line (cannot interrupt a paragraph).
- **Lists**: Bullet (`-`, `+`, `*`) or ordered (`1.`, `2)`). Sublists indent to the content column. Changing bullet character starts a new list.
- **Emphasis**: Use `*` for intraword emphasis; `_` only at word boundaries.
- **Links**: `[text](url)` or `[text][label]`. No whitespace between text and `(` or `[`.
- **Images**: `![alt](src)` — always include non-empty alt text.
- **Autolinks**: Use angle brackets (`<URL>`) — bare URLs are not CommonMark autolinks.

## Validation Checklist

- [ ] Headings use `#` + space (not underlines).
- [ ] Fenced code blocks specify a language identifier.
- [ ] Backtick fence info strings do not contain backtick characters.
- [ ] Emphasis uses `*` for intraword; `_` only at word boundaries.
- [ ] Links have no whitespace before `(` or `[`.
- [ ] Images include non-empty alt text.
- [ ] Autolinks use angle brackets.
- [ ] No unbalanced parentheses in bare link destinations.
