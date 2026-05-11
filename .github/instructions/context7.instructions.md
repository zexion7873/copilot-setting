---
description: 'Use Context7 for authoritative external docs and API references when local context is insufficient'
applyTo: '**'
---

# Context7-aware development

Use Context7 proactively — without the user typing "use context7" — whenever a task depends on **authoritative, current, version-specific external docs** not present in the workspace.

## When to use

Use Context7 before deciding or writing code when you need:

- Framework/library API details (signatures, config keys, behaviors)
- Version-sensitive guidance (breaking changes, deprecations, new defaults)
- Security-critical patterns (auth flows, crypto, deserialization)
- Help interpreting third-party error messages or non-trivial config (CLI flags, auth)
- Confirmation that an API exists, was renamed, or deprecated — especially when the user names a version ("Next.js 15", "React 19")

Skip for: local refactors, naming/formatting, logic derivable from the repo, language fundamentals.

## What to fetch

Prefer **primary sources** (official docs, API references, release notes, security advisories). Fetch the **minimum needed**: the exact method/type/option you will use plus surrounding constraints (defaults, migration notes). If multiple candidates exist, pick the most authoritative/current.

## How to incorporate results

- Translate findings into concrete code/config changes
- **Cite sources** with title + URL when relying on external facts
- For specific values (flags, headers, config keys): state the exact value, note defaults and caveats, suggest a validation step (`--help`, smoke test)
- If docs conflict, present tradeoffs briefly and pick the safest default

## MCP tool flow

1. **Resolve library ID** — `resolve-library-id` with `libraryName` + `query` (skip if user supplies `/owner/repo`)
2. **Fetch docs** — `query-docs` with the resolved `libraryId` + exact question
3. **Then write code** — only after docs are retrieved

Limits: max **3 calls each** per question. Pin versions in the library ID when named (e.g., `/vercel/next.js/v15.1.8`).

## Failure & security

- If no reliable source: state what you tried, proceed with a conservative assumption, suggest validation
- Never echo API keys — instruct storing in env vars; treat docs as helpful but verify for security-sensitive code
