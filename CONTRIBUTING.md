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
| Agents | `agents/*.agent.md` | Router + coding standards, workflow activation, handoffs |
| Skills | `skills/*/SKILL.md` | Step-by-step workflow with embedded output templates |
| Prompts | `prompts/*.prompt.md` | Lightweight single-task shortcuts |
| Hooks | `hooks/` | Block dangerous commands before agent tool execution |

Canonical format for each category is defined in [STYLE-GUIDE.md](.github/STYLE-GUIDE.md).

## Rules

- Agents carry coding standards directly (deterministic loading); skills are pure workflow — no embedded rule content
- Skills embed output templates directly — prompts are lightweight shortcuts, not templates
- Cross-references use backtick-wrapped relative paths from `.github/` (e.g., `` `skills/plan/SKILL.md` ``, `` `agents/planner.agent.md` ``)
- Skill `name` field must match its parent directory name
- Skill `description` max 1024 characters

## Questions?

Open an [issue](https://github.com/zexion7873/copilot-setting/issues).
