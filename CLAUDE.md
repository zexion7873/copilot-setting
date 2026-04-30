# CLAUDE.md

Guidance for AI assistants (Claude Code and others) working in this repository.

## What this repository is

A **GitHub Copilot configuration repository**, not an application. Every file is documentation or configuration consumed by Copilot Chat. There is no build system, no test suite, no runtime code. Changes are validated by **review of Markdown content and frontmatter**, not by compilation or execution.

The configuration is intended to be deployed to a user's `~/.github/` directory so it applies globally across projects. Most content assumes a downstream **Java 8 + Maven + no Spring Boot** target stack (a future Java 21 upgrade is noted), with **MySQL** as the default SQL dialect.

## Top-level layout

```
.
├── .github/
│   ├── copilot-instructions.md       Global base instructions (loaded every chat)
│   ├── instructions/                 Auto-applied rules, scoped by `applyTo` glob
│   ├── agents/                       Specialist agents invoked via @name in chat
│   ├── prompts/                      Reusable prompt templates (/ picker)
│   └── skills/<name>/SKILL.md        Executable skill workflows for agents
├── README.md                         English overview (source of truth for catalogs)
├── README.zh-TW.md                   Traditional Chinese mirror — keep in sync
├── CONTRIBUTING.md
├── SECURITY.md
└── LICENSE                           MIT
```

There is no `src/`, no `pom.xml`, no `package.json`. Do not add scaffolding for languages or runtimes — this repo only ships Markdown.

## File conventions by directory

Each subdirectory has its own filename suffix and YAML frontmatter shape. Match the existing pattern exactly; tooling parses these fields.

### `.github/copilot-instructions.md`
Single global file, no frontmatter. Top-level concerns only: language (responses in **Traditional Chinese 繁體中文**, code/comments in **English**), tech stack, code style, error handling, git, logging, security, performance.

### `.github/instructions/<name>.instructions.md`
Auto-loaded when a file matches `applyTo`.
```yaml
---
description: 'Short one-line description'
applyTo: '**/*.java'        # or '**', or comma-separated globs
---
```
Some files also include a `name:` field (see `global-copilot.instructions.md`, `no-heredoc.instructions.md`). Keep glob patterns honest — `applyTo: '**'` means it loads everywhere, so reserve it for genuinely universal rules.

### `.github/agents/<name>.agent.md`
Specialist personas invoked with `@<name>` in Copilot Chat.
```yaml
---
description: 'What the agent does'
name: 'Agent Display Name'
model: Claude Opus 4.6        # or Claude Sonnet 4.6 / GPT-5.3-Codex / GPT-5 mini
tools: ['search', 'read/problems', 'execute/runInTerminal']
---
```
Body sections follow a loose template: Core Responsibilities → Process → Output Format → Constraints. When adding an agent, also register it in both READMEs' agent table.

### `.github/prompts/<name>.prompt.md`
Templates surfaced via the prompt picker / `/` reference.
```yaml
---
agent: 'agent'                # most prompts; some omit this
description: 'What the prompt produces'
tools: ['search/codebase', 'edit/editFiles', ...]   # optional
---
```
Categories used in `README.md`: Context & Planning, Java, SQL, Code Quality & Git. Place new prompts in the matching table.

### `.github/skills/<name>/SKILL.md`
Executable workflow consumed by agents (and `/<name>` slash invocation in some surfaces).
```yaml
---
name: <name>                  # must match directory name
description: 'When to use, and the steps it walks through'
license: MIT
allowed-tools: ['search', 'read/problems', ...]   # or a string like 'Bash'
---
```
Body sections: Overview → Steps/Workflow → Output. Each skill lives in its own directory so additional assets (scripts, references) can be co-located later, but currently each only contains `SKILL.md`.

## Editing rules

- **Frontmatter is structural.** Preserve the exact field names and quoting style used by neighboring files. Tools key off `description`, `applyTo`, `model`, `tools`, `allowed-tools`, `name`.
- **Two READMEs, one source of truth.** `README.md` is canonical; `README.zh-TW.md` mirrors it. Any catalog change (new agent, prompt, skill, or instruction) must update **both** README tables and the directory tree near the top of `README.md`.
- **Markdown style: CommonMark 0.31.2.** See `.github/instructions/markdown.instructions.md`. Avoid GFM-only constructs unless already used.
- **No heredoc for file writes.** `.github/instructions/no-heredoc.instructions.md` forbids `cat <<EOF > file` style writes — use the Write/Edit tools. This rule applies to anyone editing the repo, including Claude.
- **Don't invent capabilities.** Agent `tools` lists, prompt `tools` lists, and skill `allowed-tools` lists describe what the surface actually exposes. Adding a tool name there does not create that capability — copy from an existing file that uses the same surface.
- **Stay in scope.** A bug fix or doc tweak should not refactor unrelated files. The system prompt's "no incidental cleanup" rule applies here too.

## Commit & branch workflow

- **Conventional Commits**, English commit messages (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`).
- One logical change per commit. Recent history shows tightly scoped commits — match that cadence.
- The active development branch for Claude-authored changes is **`claude/add-claude-documentation-BIAuG`**. Develop, commit, and push there unless the user redirects.
- Push with `git push -u origin <branch>`. Do not open a pull request unless the user explicitly asks.

## Communication & response style

The downstream Copilot persona responds in **Traditional Chinese**. That is a directive for Copilot, not for Claude Code itself — when Claude is operating on this repo, follow normal Claude Code conventions (concise English, terse updates) unless the user specifies otherwise. The Traditional Chinese rule still applies to any sample assistant text you might author *inside* the configuration files.

## Quick reference: where things live

| Goal | File |
|------|------|
| Change the global persona / response language | `.github/copilot-instructions.md` |
| Add a rule that auto-loads for `*.java` (or any glob) | new file under `.github/instructions/` |
| Add a `@new-agent` chat persona | new file under `.github/agents/` + update both READMEs |
| Add a slash-invokable skill workflow | new directory under `.github/skills/<name>/SKILL.md` + update both READMEs |
| Add a reusable prompt template | new file under `.github/prompts/` + update both READMEs |
| Update the public catalog | `README.md` and `README.zh-TW.md` (both) |

## Things to avoid

- Creating new top-level files (other than docs the user requests).
- Adding language-specific build artifacts, `.gitignore` entries for stacks not present, or CI for code that does not exist.
- Renaming existing frontmatter fields or directory names — downstream tooling depends on them.
- Editing `LICENSE` or `SECURITY.md` without explicit user request.
