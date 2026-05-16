# Contributing

## How to Contribute

1. Fork this repository
2. Create a branch (`git checkout -b feature/your-feature`)
3. Follow the [STYLE-GUIDE.md](.github/STYLE-GUIDE.md) for file format and structure
4. Verify cross-references: `grep -rn "<filename>" .github/` before renaming or moving files
5. Enable the pre-commit hook: `git config core.hooksPath .githooks`
6. Commit with [Conventional Commits](https://www.conventionalcommits.org/) messages
7. Open a Pull Request

## Architecture

Each category has one job. Content that belongs elsewhere must be delegated, not copied.

| Category | Path | Responsibility |
|---|---|---|
| Instructions | `instructions/*.instructions.md` | Coding conventions (auto-applied by `applyTo` glob) |
| Agents | `agents/*.agent.md` | Routing and handoffs |
| Skills | `skills/*/SKILL.md` | Workflow execution (output templates embedded) |
| Prompts | `prompts/*.prompt.md` | Lightweight single-task shortcuts |

Canonical format for each category is defined in [STYLE-GUIDE.md](.github/STYLE-GUIDE.md).

## Rules

- Instructions must not duplicate skill workflow content (and vice versa)
- Skills embed output templates directly — no separate prompt files
- Cross-references use relative paths from `.github/` (e.g., `instructions/sql.instructions.md`)
- Skill `name` field must match its parent directory name
- Skill `description` max 1024 characters

## Questions?

Open an [issue](https://github.com/zexion7873/copilot-setting/issues).
