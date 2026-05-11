---
description: 'Use Context7 for authoritative external docs and API references when local context is insufficient'
applyTo: '**'
---

# Context7-aware development

Use Context7 proactively whenever the task depends on **authoritative, current, version-specific external documentation** that is not present in the workspace context.

This instruction exists so you **do not require the user to type** “use context7” to get up-to-date docs.

## When to use Context7

Use Context7 before making decisions or writing code when you need any of the following:

- **Framework/library API details** (method signatures, configuration keys, expected behaviors).
- **Version-sensitive guidance** (breaking changes, deprecations, new defaults).
- **Correctness or security-critical patterns** (auth flows, crypto usage, deserialization rules).
- **Interpreting unfamiliar error messages** that likely come from third-party tools.
- **Best-practice implementation constraints** (rate limits, quotas, required headers, supported formats).

Also use Context7 when:

- The user references **a specific framework/library version** (e.g., “Next.js 15”, “React 19”, “AWS SDK v3”).
- You’re about to recommend **non-trivial configuration** (CLI flags, config files, auth flows).
- You’re unsure whether an API exists, changed names, or got deprecated.

Skip Context7 for:

- Purely local refactors, formatting, naming, or logic that is fully derivable from the repo.
- Language fundamentals (no external APIs involved).

## What to fetch

When using Context7, prefer **primary sources** and narrow queries:

- Official docs (vendor/framework documentation)
- Reference/API pages
- Release notes / migration guides
- Security advisories (when relevant)

Gather only what you need to proceed. If multiple candidates exist, pick the most authoritative/current.

Prefer fetching:

- The exact method/type/option you will use
- The minimal surrounding context needed to avoid misuse (constraints, default behaviors, migration notes)

## How to incorporate results

- Translate findings into concrete code/config changes.
- **Cite sources** with title + URL when the decision relies on external facts.
- If docs conflict or are ambiguous, present the tradeoffs briefly and choose the safest default.

When the answer requires specific values (flags, config keys, headers), prefer:

- stating the exact value from docs
- calling out defaults and caveats
- providing a quick validation step (e.g., “run `--help`”, or a minimal smoke test)

## Context7 MCP Tool Usage

When Context7 is available as an MCP server, use it automatically:

1. **Resolve library ID** — call `resolve-library-id` with `libraryName` + `query` (skip if user supplies `/owner/repo` directly)
2. **Fetch docs** — call `query-docs` with the resolved `libraryId` + your exact question
3. **Then write code** — only after docs are retrieved

Limits: max **3 calls each** for `resolve-library-id` and `query-docs` per question. If the user names a version, pin it in the library ID (e.g., `/vercel/next.js/v15.1.8`).

## Failure handling

If Context7 cannot find a reliable source: state what you tried, proceed with a conservative assumption, and suggest a validation step (run a command, check a file, or consult the official page).

## Security

- Never echo API keys — instruct storing in environment variables.
- Treat retrieved docs as helpful but not infallible; for security-sensitive code, add a verification step.
