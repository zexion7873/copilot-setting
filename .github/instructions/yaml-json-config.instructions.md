---
description: 'YAML and JSON configuration file conventions — formatting, structure, and secret management.'
applyTo: '**/*.yml, **/*.yaml, **/*.json'
---

# YAML & JSON Configuration Conventions

Conventions for YAML and JSON configuration files in this project — formatting, structure, key naming, and secret management.

## YAML Formatting

- Indentation: 2 spaces. Never tabs.
- No trailing whitespace on any line.
- Quote values that look like booleans or numbers when you mean strings: `version: '1.0'` not `version: 1.0`.
- Always quote `yes`, `no`, `on`, `off` — YAML 1.1 parses them as booleans without quotes.
- Blank line between top-level keys for readability.
- Prefer block style over flow style for multi-value structures.

## JSON Formatting

- Indentation: 2 spaces.
- No trailing commas — JSON spec forbids them; they break parsers.
- No comments — JSON has no comment syntax. Use a `"_comment"` key if documentation is unavoidable.
- All keys must be double-quoted strings.
- Validate with a linter before committing (`jsonlint`, `jq .`).

## Structure

- Flat over deeply nested. If you're past 3 levels, reconsider the shape.
- Pick one key naming convention per project and stick to it: `camelCase` or `snake_case`. Never mix.
- Group related keys together. Don't scatter `timeout` next to `log_level`.
- Avoid duplicate keys — behavior is undefined and parser-dependent.

## Security

- **Never commit secrets.** No passwords, API keys, tokens, or private certificates in config files.
- Reference environment variables: `${DB_PASSWORD}`, `${API_KEY}`.
- Use placeholder patterns for templates: `<REPLACE_WITH_SECRET>`.
- For production secrets, use an external store (Vault, AWS Secrets Manager, etc.).
- If a secret accidentally lands in git history, rotate it immediately — rewriting history is not enough.

## Java Project Common Cases

- **Docker Compose**: service names in snake_case, explicit `restart` policies, no hardcoded credentials in `environment` blocks.
- **CI/CD pipelines** (GitHub Actions, GitLab CI): pin action versions to a commit SHA, not a mutable tag.
- **Tool configs** (ESLint, Prettier, `.editorconfig`): keep in project root, document non-obvious overrides with `_comment` keys in JSON or inline comments in YAML.

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `password: mySecret123` | Secret in plaintext | `password: ${DB_PASSWORD}` |
| `enabled: yes` (unquoted) | YAML 1.1 parses as boolean `true` | `enabled: 'yes'` or `enabled: true` |
| `version: 1.0` (unquoted) | Parsed as float, not string | `version: '1.0'` |
| Trailing comma in JSON | Breaks all standard parsers | Remove it |
| 5+ levels of nesting | Unreadable, hard to override | Flatten or split into multiple files |
| Mixed `camelCase` and `snake_case` keys | Inconsistent, error-prone | Pick one, enforce via linter |
