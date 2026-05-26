# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication Language

Always reply to the user in **Traditional Chinese (繁體中文)**. File contents, code, identifiers, and commit messages remain in English per the conventions below — only the chat replies are in Chinese.

## Repository Purpose

This repo is **not application code** — it is a configuration distribution for **GitHub Copilot** that defines a multi-agent system for Java 8 / Maven / Spring Core + Hibernate 4.x projects (no Spring Boot — declarative transactions via XML `<tx:advice>`). Everything under `.github/` is content loaded by Copilot at runtime (agents, skills, prompts, hooks). When editing, you are editing prompt-engineering artifacts, not source code.

The target audience of the artifacts here is **Copilot users working in downstream Java repos**, not this repo itself. There is no build, no test suite, and no runtime — only Markdown content and one validation script.

## Validation Commands

The only executable workflow is style-guide validation. Run before committing changes under `.github/`:

```bash
bash .github/scripts/validate-style-guide.sh
```

This is also enforced in CI (`.github/workflows/validate-style-guide.yml`) on any PR that touches `.github/**/*.md`. It checks: frontmatter on skills / agents / prompts; that `skills/<name>/SKILL.md` has `name` matching the directory, a `description` ≤ 1024 chars carrying the required markers (`Use when` / `Triggers on:` / `Do NOT use`, unless `disable-model-invocation: true`), and no `tools` field (tools belong on agents); that code-touching agents (`implementer`, `reviewer`, `debugger`) have a `## Coding Standards` section; that agent `handoffs[].agent` references resolve; and that canonical cross-references (`` `skills/.../SKILL.md` ``, `` `agents/....agent.md` ``) point to real files.

One-time local setup so the validator also runs on `git commit`:

```bash
git config core.hooksPath .githooks
```

`.githooks/pre-commit` runs the validator only when staged paths match `.github/**/*.md`, so unrelated commits aren't slowed down.

## Architecture

```text
Hooks ──lifecycle guard──→ Agent (Router + Coding Standards)
                             │
                             └──activates──→ Skill (Workflow + Output Template)

Prompt (Shortcut) ──manual /prompt-name──→ Standalone execution
```

| Category | Path | Role | Loads when |
|---|---|---|---|

| Agents | `.github/agents/*.agent.md` | Router — activates workflows, manages handoffs | User types `@agent-name` |
| Skills | `.github/skills/<name>/SKILL.md` | Step-by-step workflow process (output templates embedded) | Description matches user intent, or `/skill-name` |
| Prompts | `.github/prompts/*.prompt.md` | Lightweight single-task shortcuts | Manual invocation (`/prompt-name`) |
| Hooks | `.github/hooks/default.json` + `scripts/` | Block dangerous shell commands pre-tool | Agent tool-use events |

**Critical separation-of-concerns rule:** each category has exactly one job. Agents carry coding standards in a `## Coding Standards` section for deterministic loading. Skills embed their own output templates directly and are pure workflow — no rule content.

**Coding standards placement:** Coding standards live in agent files (`## Coding Standards` section) for deterministic loading. Skills are pure workflow — no rule content.

## Canonical Format — STYLE-GUIDE.md

`.github/STYLE-GUIDE.md` is the authoritative format spec for every file under `.github/`. Before adding or restructuring any agent / skill, read the matching skeleton in STYLE-GUIDE.md. Format changes to any category require updating STYLE-GUIDE.md **first**, then propagating to existing files.

Per-category key constraints (full rules in STYLE-GUIDE.md):

- **Agents** — frontmatter requires `name`, `description`, `model`, `tools`. Code-touching agents have `## Coding Standards`. Body section order is fixed: `Skill Activation` → `Subagent Delegation` → `Workflow` → `Constraints` → `Handoff Guidance`.
- **Skills** — frontmatter is exactly `name` + `description`. **No `tools` field on skills** (tools belong on agents — validator enforces this). `description` is ≤ 1024 chars and follows the strict three-part format: `Use when …. Triggers on: …. <one-sentence summary>. Do NOT use for …`. H1 is always `<Name> — Workflow`. Skill `name` must match its directory name.
- **Prompts** — frontmatter is `agent` + `description`. Lightweight single-task shortcuts invoked via `/prompt-name`. Not output templates (those are embedded in skills).

## Cross-Reference Format

All cross-references use backtick-wrapped **relative paths from `.github/`**, never bare names:

| Type | Format |
|---|---|

| Skill | `` `skills/plan/SKILL.md` `` |
| Output template | Embedded in the paired `skills/<name>/SKILL.md` |
| Agent file | `` `agents/planner.agent.md` `` |
| Agent mention (in chat) | `` `@implementer` `` |
| Skill mention (inline) | `` `plan` skill `` |

## Maintenance Rule — Inbound Reference Check

Cross-references are not enforced by the validator. Before renaming or moving any file under `.github/`, scan for inbound references:

```bash
grep -rn "<old-filename>" .github/
```

Broken paths silently degrade Copilot output — they don't error, they just stop loading the referenced content.

## Bilingual Conventions

This repo intentionally mixes languages. Respect the split:

- **All `.github/` content** (agents, skills, prompts) — English, because Copilot may inject it into any user's prompt context.
- **README has two versions**: `README.md` (English) and `README.zh-TW.md` (Traditional Chinese). Keep them in sync when changing either.
- **`.github/copilot-instructions.md`** declares the downstream-user contract: respond in Traditional Chinese, but code/comments/identifiers in English. Do not mistake this for guidance on how to edit this repo.

## Hooks — Dangerous-Command Block List

`.github/hooks/scripts/block-dangerous-commands.sh` denies shell tool calls matching these patterns (case-insensitive): `rm -rf /`, `rm -rf .`, `rm -rf *`, `--no-preserve-root`, `sudo `, `DROP DATABASE`, `DROP SCHEMA`, `DROP TABLE`, `TRUNCATE`, `git push --force` (any branch), `git reset --hard`, `git clean -fd`, `chmod -R 777`, `mkfs.`, `curl|sh` / `wget|sh`, `dd if=`, `kill -9 -1`. If you genuinely need one of these in development, run it directly outside the agent — do not bypass the hook.

## Commit & PR Process

- Conventional Commits (see `.github/skills/git-commit/SKILL.md` for the type table — `feat` / `fix` / `docs` / `refactor` / `perf` / `test` / `build` / `ci` / `chore` / `revert`).
- The `git-commit` skill is marked `disable-model-invocation: true` and **must** be invoked explicitly via `/git-commit` — never auto-trigger.
- PR workflow per `CONTRIBUTING.md`: branch from `main`, follow `STYLE-GUIDE.md`, run the inbound-reference grep before renaming files, run `validate-style-guide.sh` locally.

## Agent Roster (for orientation)

| Agent | Model | Activates |
|---|---|---|
| `@planner` | Claude Opus 4.6 | `plan`, `tasks`, `clarify-task` |
| `@implementer` | GPT-5.3-Codex | `implement`, `refactor`, `test-design`, `performance` |
| `@reviewer` | Claude Opus 4.6 | `code-review`, `security-audit`, `sql-review`, `schema-migration-review`, `pom-review` |
| `@debugger` | Claude Opus 4.6 | `debug` |
| `@researcher` | Claude Haiku 4.5 | Read-only subagent invoked by `@planner` / `@implementer` |

When adding a new skill: pick the owning agent, list the skill in that agent's `Skill Activation` table, and add bidirectional Handoffs entries if it interacts with other skills.
