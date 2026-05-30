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
| Instructions | `instructions/*.instructions.md` | Coding conventions (loaded when a matching file is in context, via `applyTo`) |
| Agents | `agents/*.agent.md` | Routing and handoffs |
| Skills | `skills/*/SKILL.md` | Workflow execution (output templates embedded) |
| Prompts | `prompts/*.prompt.md` | Lightweight single-task shortcuts |

Canonical format for each category is defined in [STYLE-GUIDE.md](.github/STYLE-GUIDE.md).

## Verifying loading behavior

The validator only checks file *format*, not whether Copilot actually loads a file at runtime. When you change **how rules reach Copilot** — moving them between agent bodies (`## Coding Standards`), skill instruction-references, or `applyTo` globs — verify the change manually in VS Code. There is no automated test for runtime loading.

1. Install this `.github/` config into a scratch repo that contains at least one `.java` file, and open it in VS Code with Copilot.
2. **Agent-body embed** — start a new chat with **no file attached**, select `@implementer`, and ask it to "write a method returning a list of three fixed strings." Pass: it uses Java 8 constructs (`Arrays.asList`, not `List.of()` / `var` / records) and never suggests Spring Boot or JPA — proving the `## Coding Standards` block loaded on agent selection.
3. **Glob path** — repeat with the `.java` file attached via `#file:`. The per-file-type instruction files should also load; confirm via the chat **References** list.

If step 2 fails (modern-Java output with no file attached), the agent-body embed is not injecting and the loading architecture needs rework.

## Rules

- Instructions must not duplicate skill workflow content (and vice versa)
- Skills embed output templates directly — prompts are lightweight shortcuts, not templates
- Cross-references use relative paths from `.github/` (e.g., `instructions/sql.instructions.md`)
- Skill `name` field must match its parent directory name
- Skill `description` max 1024 characters

## Questions?

Open an [issue](https://github.com/zexion7873/copilot-setting/issues).
