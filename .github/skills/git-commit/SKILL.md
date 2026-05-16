---
name: git-commit
description: 'Conventional commit message generation and staging.'
disable-model-invocation: true
---

# Git Commit — Workflow

⚠️ Manual only — invoke via `/git-commit`. Never auto-triggered.

## Steps

1. **Analyze diff**: `git diff --staged` (or `git diff` if nothing staged)
2. **Stage files**: add relevant changes; exclude unrelated modifications
3. **Generate message**: Conventional Commits format

## Message Format

```
<type>(<scope>): <subject>

<body — optional, explains WHY>
```

### Types

| Type | When |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or correcting tests |
| `build` | Build system or external dependencies |
| `ci` | CI configuration |
| `chore` | Maintenance tasks |
| `revert` | Revert a previous commit |

## Rules

- Subject: imperative mood, lowercase, no period, ≤72 chars
- Body: wrap at 72 chars; explain motivation, not mechanics
- One logical change per commit — don't mix features with refactoring
- Never commit secrets, credentials, or `.env` files
