# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication Language

Always reply to the user in **Traditional Chinese (繁體中文)**. File contents, code, identifiers, and commit messages remain in English per the conventions below — only the chat replies are in Chinese.

## Repository Purpose

This repo is **not application code** — it is a configuration distribution for **GitHub Copilot** that defines a multi-agent system for Java 8 / Maven projects (no Spring Boot). Everything under `.github/` is content loaded by Copilot at runtime (agents, skills, instructions, prompts, hooks). When editing, you are editing prompt-engineering artifacts, not source code.

The target audience of the artifacts here is **Copilot users working in downstream Java repos**, not this repo itself. There is no build, no test suite, and no runtime — only Markdown content and one validation script.

## Validation Commands

The only executable workflow is style-guide validation. Run before committing changes under `.github/`:

```bash
bash .github/scripts/validate-style-guide.sh
```

This is also enforced in CI (`.github/workflows/validate-style-guide.yml`) on any PR that touches `.github/**/*.md`. It checks frontmatter on instructions / skills / prompts / agents, that `skills/<name>/SKILL.md` has `name` matching the directory, that skill `description` is ≤ 1024 chars, and that skill frontmatter has no `tools` field (tools belong on agents).

## Architecture — Five Categories, One Job Each

```text
Hooks ──lifecycle guard──→ Agent (Router)
                             │
                             └──activates──→ Skill (Workflow) ──output format──→ Prompt (Template)
                                                  │
                                                  └──rules──→ Instruction (Rules)
```

| Category | Path | Role | Loads when |
|---|---|---|---|
| Instructions | `.github/instructions/*.instructions.md` | Single source of truth for coding conventions | File matching `applyTo` glob is focused |
| Agents | `.github/agents/*.agent.md` | Router — activates workflows, manages handoffs | User types `@agent-name` |
| Skills | `.github/skills/<name>/SKILL.md` | Step-by-step workflow process | Description matches user intent, or `/skill-name` |
| Prompts | `.github/prompts/*.prompt.md` | Output-format scaffolds | Paired skill cites them; or `/prompt-name` |
| Hooks | `.github/hooks/default.json` + `scripts/` | Block dangerous shell commands pre-tool | Agent tool-use events |

**Critical separation-of-concerns rule:** each category has exactly one job. Content that belongs in another category must be **referenced**, not copied. Skills must not embed shared templates inline — they reference prompt files. Instructions must not contain workflow content. Skills must not contain rule lists that duplicate instructions (with one exception below).

**Fallback rules exception:** In agent chat, instruction files only auto-load when a matching file is focused in the editor. So code-touching skills (`implement`, `refactor`, `code-review`, `sql-review`, `security-audit`, `debug`, `performance`) intentionally inline a short bullet list of the **critical non-negotiable rules** at the top of `SKILL.md`. This is the only sanctioned duplication — keep it short and treat the instruction file as canonical.

## Canonical Format — STYLE-GUIDE.md

`.github/STYLE-GUIDE.md` is the authoritative format spec for every file under `.github/`. Before adding or restructuring any agent / skill / instruction / prompt, read the matching skeleton in STYLE-GUIDE.md. Format changes to any category require updating STYLE-GUIDE.md **first**, then propagating to existing files.

Per-category key constraints (full rules in STYLE-GUIDE.md):

- **Instructions** — frontmatter is exactly `description` + `applyTo`. H1 is a descriptive title (no filename suffix). Anti-Patterns table is always 3-column `Pattern | Problem | Fix`.
- **Agents** — frontmatter requires `name`, `description`, `model`, `tools`. Body section order is fixed: `Skill Activation` → `Subagent Delegation` → `Workflow` → `Constraints` → `Handoff Guidance`.
- **Skills** — frontmatter is exactly `name` + `description`. **No `tools` field on skills** (tools belong on agents — validator enforces this). `description` is ≤ 1024 chars and follows the strict three-part format: `Use when …. Triggers on: …. <one-sentence summary>. Do NOT use for …`. H1 is always `<Name> — Workflow`. Skill `name` must match its directory name.
- **Prompts** — frontmatter is `agent` + `description`. Subtype is determined by filename suffix: `-template` (one-shot scaffold), `-checklist` (verification list), `-output` (cheat-sheet reference). Each subtype has its own skeleton.

## Cross-Reference Format

All cross-references use backtick-wrapped **relative paths from `.github/`**, never bare names:

| Type | Format |
|---|---|
| Instruction | `` `instructions/sql-rules.instructions.md` `` |
| Skill | `` `skills/plan/SKILL.md` `` |
| Prompt | `` `prompts/plan-template.prompt.md` `` |
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

- **All `.github/` content** (instructions, agents, skills, prompts) — English, because Copilot may inject it into any user's prompt context.
- **README has two versions**: `README.md` (English) and `README.zh-TW.md` (Traditional Chinese). Keep them in sync when changing either.
- **`.github/copilot-instructions.md`** declares the downstream-user contract: respond in Traditional Chinese, but code/comments/identifiers in English. Do not mistake this for guidance on how to edit this repo.

## Hooks — Dangerous-Command Block List

`.github/hooks/scripts/block-dangerous-commands.sh` denies shell tool calls matching these patterns (case-insensitive): `rm -rf /`, `sudo `, `DROP DATABASE`, `DROP SCHEMA`, `TRUNCATE `, `git push --force` to `main`/`master`, `chmod -R 777`, `mkfs.`. If you genuinely need one of these in development, run it directly outside the agent — do not bypass the hook.

## Commit & PR Process

- Conventional Commits (see `.github/skills/git-commit/SKILL.md` for the type table — `feat` / `fix` / `docs` / `refactor` / `perf` / `test` / `build` / `ci` / `chore` / `revert`).
- The `git-commit` skill is marked `disable-model-invocation: true` and **must** be invoked explicitly via `/git-commit` — never auto-trigger.
- PR workflow per `CONTRIBUTING.md`: branch from `main`, follow `STYLE-GUIDE.md`, run the inbound-reference grep before renaming files, run `validate-style-guide.sh` locally.

## Agent Roster (for orientation)

| Agent | Model | Activates |
|---|---|---|
| `@planner` | Claude Opus 4.6 | `plan`, `sdd`, `tasks`, `clarify-task` |
| `@implementer` | GPT-5.3-Codex | `implement`, `refactor`, `test-design`, `performance` |
| `@reviewer` | Claude Opus 4.6 | `code-review`, `security-audit`, `sql-review`, `sdd-review` |
| `@debugger` | Claude Opus 4.6 | `debug` |
| `@researcher` | Claude Haiku 4.5 | Read-only subagent invoked by `@planner` / `@implementer` |

When adding a new skill: pick the owning agent, list the skill in that agent's `Skill Activation` table, and add bidirectional Handoffs entries if it interacts with other skills.
