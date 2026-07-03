# copilot-setting — Agent Guide

**Canonical** guidance for any AI agent (Claude Code, OpenAI Codex, Cursor, GitHub Copilot, …) working in this repository. `CLAUDE.md` is a thin pointer that imports this file via `@AGENTS.md`, so every tool reads one source of truth; the authoritative *format* spec is `.github/STYLE-GUIDE.md`. Read both before editing. There are intentionally no per-directory `AGENTS.md` files — keep navigation in this single root file.

## Communication Language

Always reply to the user in **Traditional Chinese (繁體中文)**. File contents, code, identifiers, and commit messages remain in English per the conventions below — only the chat replies are in Chinese.

## Repository Purpose

This repo is **not application code** — it is a configuration distribution for **GitHub Copilot** that defines a multi-agent system for Java 8 / Maven / Spring Core 3.2 + Hibernate 4.2 projects (no Spring Boot — declarative transactions via XML `<tx:advice>`). Everything under `.github/` is content loaded by Copilot at runtime (agents, skills, instructions, prompts, hooks). When editing, you are editing prompt-engineering artifacts, not source code.

The target audience of the artifacts here is **Copilot users working in downstream Java repos**, not this repo itself. There is no build, no test suite, and no runtime — only Markdown content and one validation script.

> Not part of the product (ignored state / dependencies / IDE config): `.omc/`, `.omo/`, `.claude/`, `.codegraph/`, `.sisyphus/`, `.idea/`, `.vscode/`.

## Validation Commands

Run both before committing changes under `.github/` (also enforced in CI via `.github/workflows/validate-style-guide.yml`):

```bash
bash .github/scripts/test-validate-style-guide.sh   # regression-test the validator itself
bash .github/scripts/validate-style-guide.sh        # validate the real tree
```

One-time local setup so the validator also runs on `git commit` (`.githooks/pre-commit` runs it against the staged index when `.github/` markdown is staged):

```bash
git config core.hooksPath .githooks
```

The validator enforces: frontmatter presence with a terminated block, single-line `description` / `agent` scalars, skill `description` ≤ 1024 chars, skill `name`-matches-directory, no `tools` field on skills, agent required frontmatter keys, byte-identical agent `## Coding Standards` floor across `implementer` / `reviewer` / `debugger`, the floor↔instruction anchor canary, and resolution of path-style cross-references (`instructions/…`, `skills/…/SKILL.md`, `agents/….agent.md`, `prompts/….prompt.md`), handoff targets, and backtick-wrapped prompt mentions. Full machine-checked rule list: `.github/STYLE-GUIDE.md` → "Tier 1: Machine-checked".

## Architecture

```text
Hooks ──lifecycle guard──→ Agent (Router)
                             │
                             └──activates──→ Skill (Workflow + Output Template)
                                                  │
                                                  └──rules──→ Instruction (Rules)

Prompt (Shortcut) ──manual /prompt-name──→ Standalone execution
```

| Category | Path | Role | Loads when |
|---|---|---|---|
| Agents (5) | `.github/agents/*.agent.md` | Router — activates workflows, manages handoffs | User selects the agent from the chat agents dropdown |
| Skills (11) | `.github/skills/<name>/SKILL.md` | Step-by-step workflow process (output templates embedded) | Description matches user intent, or `/skill-name` |
| Instructions (8) | `.github/instructions/*.instructions.md` | Single source of truth for coding conventions | A file matching `applyTo` glob is explicitly in context at request time (e.g. via `#file:`, editor attachment), or the model loads it on demand via semantic match on its `description` (discretionary); `applyTo: "**"` loads on every request |
| Prompts (4) | `.github/prompts/*.prompt.md` | Lightweight single-task shortcuts | Manual invocation (`/prompt-name`) |
| Hooks | `.github/hooks/default.json` + `scripts/` | Block dangerous shell commands pre-tool | Agent tool-use events |

**Critical separation-of-concerns rule:** each category has exactly one job. Content that belongs in another category must be **referenced**, not copied. Skills embed their own output templates directly. Instructions must not contain workflow content. Skills must not contain rule lists that duplicate instructions, save the two narrow exceptions noted below.

**Instruction loading model:** instructions reach the model through two channels, and only the first is deterministic:

1. **Glob injection at request time** — `applyTo` globs match files explicitly in context (attached via `#file:`, editor attachment); matching instruction files auto-attach. Files the agent reads or edits dynamically during execution do NOT retroactively trigger glob instructions — the VS Code mid-session refresh request (microsoft/vscode#282964) was closed as not planned.
2. **On-demand semantic loading** — each request also carries a list of all instruction files (glob + `description`); the model may load one whose description matches the task. Model-discretionary, never guaranteed. `applyTo: "**"` is the only guaranteed always-on glob.

Because most skill invocations happen without an attached file and on-demand loading cannot be relied on, hard-boundary rules (Java 8 / Spring 3.2 / Hibernate 4.2 / SQL / security) are embedded directly in the code-touching agent bodies (`implementer`, `reviewer`, `debugger`) under `## Coding Standards`, loading deterministically when the agent is selected. Code-touching skills (`implement`, `refactor`, `code-review`, `sql-review`, `security-audit`, `debug`) additionally name the canonical instruction file(s) they map to, opened on demand when the model reads the skill body. The files under `instructions/` remain the single source of truth; the agent-body embed is a deliberately minimal hard-boundary floor, not a full copy.

**Two narrow duplications are sanctioned**, both keeping the instruction file canonical:

- the version-lock hard-boundary embed in the code-touching agent bodies;
- skill verification checklists, self-verify gates, and one-line convention recaps inside workflow phases (e.g. `code-review`, `security-audit`, `sql-review`, `implement`) — which may *name* canonical conventions as one-line check items but must not add detail beyond the instruction file.

Keep both minimal; full rule restatement with added detail in a skill is a defect.

## Canonical Format — STYLE-GUIDE.md

`.github/STYLE-GUIDE.md` is the authoritative format spec for every file under `.github/`. Before adding or restructuring any agent / skill / instruction, read the matching skeleton in STYLE-GUIDE.md. Format changes to any category require updating STYLE-GUIDE.md **first**, then propagating to existing files.

## Cross-Reference Format & Inbound Reference Check

All cross-references use backtick-wrapped **relative paths from `.github/`**, never bare names:

| Type | Format |
|---|---|
| Instruction | `` `instructions/sql.instructions.md` `` |
| Skill | `` `skills/plan/SKILL.md` `` |
| Output template | Embedded in the paired `skills/<name>/SKILL.md` |
| Agent file | `` `agents/planner.agent.md` `` |
| Agent mention (in chat) | `` `@implementer` `` |
| Skill mention (inline) | `` `plan` skill `` |

The validator only resolves path-style cross-references (`instructions/…`, `skills/…/SKILL.md`, `agents/….agent.md`, `prompts/….prompt.md`), handoff targets, and backtick-wrapped prompt mentions, and it only scans files under `.github/` — `@agent` mentions, inline skill names, and references from root files (`README.md`, `AGENTS.md`) are not checked. Before renaming or moving any file under `.github/`, scan for inbound references:

```bash
grep -rn "<old-filename>" .github/
```

Broken paths silently degrade Copilot output — they don't error, they just stop loading the referenced content.

When **deleting or merging** a file, the path grep alone is not enough — several places reference skills/prompts by *name* in hardcoded lists. Follow the sweep checklist in `.github/STYLE-GUIDE.md` → File Lifecycle → Removing or Merging Files.

## Maintenance Rule — Keep Injected Context Lean & Stable

`instructions/`, `agents/`, and `skills/` content is injected into every downstream Copilot session's context window, so treat it as context engineering, not free text:

- **Lean** — every line ships into every user's context, so cut whatever doesn't earn its place. Trim for clarity and correctness, not to chase a token count.
- **Stable** — editing these files shifts downstream behaviour between versions, so batch edits decisively and keep them stable between releases — land prompt-engineering changes together in one atomic, reviewable release, not a drip of small commits.

## Maintenance Rule — List Ordering

Lists in `README.md`, `README.zh-TW.md`, and this file follow one of two deliberate orders:

- **Mirror lists** (filesystem/catalog claims — the "What Copilot Loads" tree, the Skills / Prompts / Instructions reference tables): directories first, then files, alphabetical at every level, verifiable against `ls` at a glance.
- **Narrative lists** (pipeline-teaching — the How It Works and Architecture tables, the Agents table, the Typical Workflow sections): order follows the user journey / activation chain — the order itself is content; do not alphabetize.

## Bilingual Conventions

This repo intentionally mixes languages. Respect the split:

- **All `.github/` content** (instructions, agents, skills) — English, because Copilot may inject it into any user's prompt context.
- **README has two versions**: `README.md` (English) and `README.zh-TW.md` (Traditional Chinese). Keep them in sync when changing either.
- **`.github/copilot-instructions.md`** declares the downstream-user contract: respond in Traditional Chinese, but code/comments/identifiers in English. Do not mistake this for guidance on how to edit this repo.

## Hooks — Dangerous-Command Block List

`.github/hooks/scripts/block-dangerous-commands.sh` denies shell tool calls matching a blocklist (destructive `rm`/SQL/git, privilege escalation, `curl|sh`, and similar); the script and its regression suite (`bash .github/hooks/scripts/test-block-dangerous-commands.sh`, also run in CI) are the source of truth for the exact patterns, categories, and carve-outs. The hook is **fail-closed** — empty/whitespace-only input, JSON parse errors, or missing `jq` all → deny.

This is a **last-resort safety net, not a sandbox** — blocklists are inherently bypassable via encoding, aliases, or variable indirection. Downstream repos should run agents in restricted-permission environments. If you genuinely need one of these in development, run it directly outside the agent — do not bypass the hook.

## Commit & PR Process

- Conventional Commits (see `.github/skills/git-commit/SKILL.md` for the type table — `feat` / `fix` / `docs` / `refactor` / `perf` / `test` / `build` / `ci` / `chore` / `revert`).
- The `git-commit` skill is marked `disable-model-invocation: true` and **must** be invoked explicitly via `/git-commit` — never auto-trigger.
- PR workflow per `CONTRIBUTING.md`: branch from `main`, follow `STYLE-GUIDE.md`, run the inbound-reference grep before renaming files, run `validate-style-guide.sh` locally.

## Agent Roster (for orientation)

| Agent | Model | Activates |
|---|---|---|
| `@planner` | Claude Opus 4.8 | `plan`, `tasks` |
| `@implementer` | GPT-5.3-Codex | `implement`, `source-check`, `refactor`, `test-design` |
| `@reviewer` | Claude Opus 4.8 | `code-review`, `security-audit`, `sql-review` |
| `@debugger` | Claude Sonnet 4.6 | `debug` |
| `@researcher` | GPT-5.4 mini | Read-only subagent invoked by `@planner` / `@implementer` / `@reviewer` |

When adding a new skill: pick the owning agent, list the skill in that agent's `Skill Activation` table, and add downstream (`→`) Handoffs entries if it hands off to other skills — skill Handoffs list downstream links only, never `←` upstream lines.

<!-- MANUAL: Custom project notes can be added below -->
