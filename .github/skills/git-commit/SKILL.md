---
name: git-commit
description: 'Conventional commit message generation and staging.'
disable-model-invocation: true
---

# Git Commit — Workflow

⚠️ Manual only — invoke via `/git-commit`. Never auto-triggered.

## Process

1. Analyze diff: `git diff --staged` (or `git diff` if nothing staged)
2. Stage relevant changes; exclude unrelated modifications
3. Generate message in Conventional Commits format

## Message Format

```
<type>(<scope>): <subject>

<body — optional, explains WHY>
```

| Type | When |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | No behavior change |
| `perf` | Performance improvement |
| `test` | Tests |
| `build` | Build system / dependencies |
| `ci` | CI configuration |
| `chore` | Maintenance |
| `revert` | Revert previous commit |

## Rules

- Subject: imperative mood, lowercase, no period, ≤72 chars
- Body: wrap at 72 chars; explain motivation, not mechanics
- One logical change per commit
- Never commit secrets, credentials, or `.env` files
