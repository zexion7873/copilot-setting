---
agent: 'agent'
description: 'Stage related changes and commit with a Conventional Commits message'
---

Stage the relevant changes and create a git commit with a Conventional Commits message:

1. Analyze the diff: `git diff --staged` (or `git diff` if nothing is staged); stage related changes only — exclude unrelated modifications
2. Write the message as `<type>(<scope>): <subject>` — types: feat / fix / docs / refactor / perf / test / build / ci / chore / revert; subject in imperative mood, lowercase, no period, ≤72 chars; optional body wrapped at 72 chars explaining WHY
3. One logical change per commit — don't mix features with refactoring
4. Never commit secrets, credentials, or `.env` files
5. Run `git commit`; if a pre-commit hook rejects it, report the hook output and fix the flagged files — never bypass with `--no-verify`
