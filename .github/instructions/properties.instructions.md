---
description: 'Java properties file conventions — key naming, organization, encoding, and secret management.'
applyTo: '**/*.properties'
---

# Java Properties File Conventions

## Key Naming

- Dot-separated, all lowercase: `db.connection.url`, `mail.smtp.host`, `cache.ttl.seconds`
- Hierarchical grouping: shared prefix for related keys (`db.*`, `mail.*`, `app.*`)
- No camelCase, no underscores, no hyphens in key names
- Boolean keys: `feature.x.enabled` (not `feature.x.active` or `isFeatureXEnabled`)

## Organization

- Group related keys under a shared prefix; separate groups with a blank line
- Each group preceded by a `# --- Group Name ---` header comment
- Keys within a group ordered from general to specific
- No interleaving of unrelated keys

```properties
# --- Database ---
db.driver=com.mysql.cj.jdbc.Driver
db.url=jdbc:mysql://localhost:3306/mydb
db.username=app_user
db.password=${DB_PASSWORD}

# --- Mail ---
mail.smtp.host=smtp.example.com
mail.smtp.port=587
```

## Encoding

- Default encoding is ISO 8859-1 (Java `Properties.load(InputStream)`)
- Non-ASCII characters must use Unicode escapes: `\u4e2d\u6587` not raw UTF-8 bytes
- If loading with `InputStreamReader` + explicit charset or Maven filtering, document the encoding at the top of the file: `# encoding: UTF-8`
- Never mix encoding strategies within the same file

## Value Conventions

- No trailing whitespace on any line — it becomes part of the value
- Multiline values use `\` continuation at end of line; indent continuation lines for readability
- Leading whitespace after `=` is trimmed by `Properties`; trailing whitespace is not
- Empty string: `key=` (no space, no quotes)
- Do not quote string values — quotes are literal characters in `.properties`

## Environment-Specific Config

- Profile naming: `config-dev.properties`, `config-test.properties`, `config-prod.properties`
- Shared defaults in `config.properties`; profile files override only what differs
- Use placeholder tokens for values injected at build/deploy time: `db.url=${DB_URL}`
- Document every placeholder with a comment explaining expected format

## Security

- **NEVER commit secrets** (passwords, API keys, tokens, private keys) to version control
- Sensitive keys must use environment variable placeholders: `db.password=${DB_PASSWORD}`
- Mark sensitive keys with `# SENSITIVE` comment on the preceding line
- Store secrets in environment variables, a secrets manager (e.g., HashiCorp Vault), or CI/CD secret injection
- `.properties` files containing real secrets must be in `.gitignore`

## Anti-Patterns

| Anti-pattern | Why it's wrong | Fix |
|---|---|---|
| `DB_URL=jdbc:...` | Uppercase breaks naming convention | `db.url=jdbc:...` |
| `db.password=s3cr3t` | Secret committed in plaintext | `db.password=${DB_PASSWORD}` |
| `key = value ` | Trailing space is part of the value | `key=value` |
| `name="John Doe"` | Quotes are literal, not delimiters | `name=John Doe` |
| Raw UTF-8 Chinese in ISO file | Corrupts on load | Use `\uXXXX` escapes |
| All keys in one flat block | Unreadable at scale | Group by prefix with headers |
