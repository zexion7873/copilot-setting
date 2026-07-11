# Contributing

## How to Contribute

1. Fork this repository
2. Create a branch from `main` (`git checkout -b feature/your-feature`)
3. Follow the [STYLE-GUIDE.md](.github/STYLE-GUIDE.md) for file format and structure
4. Verify cross-references: `grep -rn "<filename>" .github/` before renaming or moving files
5. Enable the pre-commit hook: `git config core.hooksPath .githooks`
6. Commit with [Conventional Commits](https://www.conventionalcommits.org/) messages
7. Run the validator before opening the PR: `bash .github/scripts/validate-style-guide.sh` — it checks frontmatter presence and termination, single-line `description` / `agent` scalars, skill `description` ≤ 1024 chars, skill `name` matching its directory, no `tools` field on skills, agent required frontmatter keys, byte-identical agent `## Coding Standards` bullets across `implementer` / `reviewer` / `debugger`, the floor↔instruction anchor canary, and resolution of path-style cross-references, handoff targets, and backtick-wrapped prompt mentions. CI enforces it on any change touching `.github/**/*.md`, the validator script, `.github/hooks/**`, or the workflow file (the pre-commit hook from step 5 only covers staged `.github/` markdown)
8. Open a Pull Request

## Architecture

See [AGENTS.md](AGENTS.md) → Architecture for the category table and separation-of-concerns rules.

## Verifying loading behavior

The validator only checks file *format*, not whether Copilot actually loads a file at runtime. When you change **how rules reach Copilot** — moving them between agent bodies (`## Coding Standards`), skill instruction-references, or `applyTo` globs — verify the change manually in VS Code. There is no automated test for runtime loading.

1. Install this `.github/` config into a scratch repo that contains at least one `.java` file, and open it in VS Code with Copilot.
2. **Agent-body embed** — start a new chat with **no file attached**, select `@implementer`, and ask it to "write a method returning a list of three fixed strings." Pass: it uses Java 8 constructs (`Arrays.asList`, not `List.of()` / `var` / records) and never suggests Spring Boot or JPA — proving the `## Coding Standards` block loaded on agent selection.
3. **Glob path** — repeat with the `.java` file attached via `#file:`. The per-file-type instruction files should also load; confirm via the chat **References** list.

If step 2 fails (modern-Java output with no file attached), the agent-body embed is not injecting and the loading architecture needs rework.

## Questions?

Open an [issue](https://github.com/zexion7873/copilot-setting/issues).
