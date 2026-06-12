<!-- Generated: 2026-06-03 | Updated: 2026-06-10 -->

# copilot-setting — Agent Guide

**Canonical** guidance for any AI agent (Claude Code, OpenAI Codex, Cursor, GitHub Copilot, …) working in this repository. `CLAUDE.md` is a thin pointer that imports this file via `@AGENTS.md`, so every tool reads one source of truth; the authoritative *format* spec is `.github/STYLE-GUIDE.md`. Read both before editing. There are intentionally no per-directory `AGENTS.md` files — keep navigation in this single root file.

## Communication Language

Always reply to the user in **Traditional Chinese (繁體中文)**. File contents, code, identifiers, and commit messages remain in English per the conventions below — only the chat replies are in Chinese.

## Repository Purpose

This repo is **not application code** — it is a configuration distribution for **GitHub Copilot** that defines a multi-agent system for Java 8 / Maven / Spring Core 3.2 + Hibernate 4.2 projects (no Spring Boot — declarative transactions via XML `<tx:advice>`). Everything under `.github/` is content loaded by Copilot at runtime (agents, skills, instructions, prompts, hooks). When editing, you are editing prompt-engineering artifacts, not source code.

The target audience of the artifacts here is **Copilot users working in downstream Java repos**, not this repo itself. There is no build, no test suite, and no runtime — only Markdown content and one validation script.

## Top-Level Files

| File | Description |
|------|-------------|
| `AGENTS.md` | **Canonical** guidance for AI agents editing this repo — architecture, separation-of-concerns rules, maintenance protocols. This file is the source of truth. |
| `CLAUDE.md` | Thin pointer — a single `@AGENTS.md` import so Claude Code (which reads `CLAUDE.md`) shares this exact file. Do not duplicate content into it. |
| `CONTRIBUTING.md` | PR workflow: branch from `main`, follow STYLE-GUIDE, run inbound-reference grep, run validator |
| `README.md` / `README.zh-TW.md` | Project overview (English + Traditional Chinese) — keep in sync |
| `SECURITY.md` | Security policy and disclosure process |

> Not part of the product (ignored state / dependencies / IDE config): `.omc/`, `.omo/`, `.claude/`, `.codegraph/`, `.sisyphus/`, `.idea/`, `.vscode/`.

## Validation Commands

The only executable workflow is style-guide validation. Run before committing changes under `.github/`:

```bash
bash .github/scripts/validate-style-guide.sh
```

This is also enforced in CI (`.github/workflows/validate-style-guide.yml`) on any PR that touches `.github/**/*.md`, the validator script, `.github/hooks/**`, or the workflow file. It checks: frontmatter on instructions / skills / agents / prompts; that `skills/<name>/SKILL.md` has `name` matching the directory, a `description` ≤ 1024 chars carrying the required markers (`Use when` / `Triggers on:` / `Do NOT use`, unless `disable-model-invocation: true`), and no `tools` field (tools belong on agents); that each code-touching skill names the canonical instruction file(s) it maps to (a `instructions/...` reference), and that each code-touching agent (implementer/reviewer/debugger) embeds a `## Coding Standards` section whose hard-boundary bullets are byte-identical across the three (and are top-level `- ` items only — indented sub-bullets, `*`/`+` bullets, or numbered lines that would escape the byte-identity check are rejected); that instruction Anti-Patterns tables use the 3-column `Pattern | Problem | Fix` header; that agent `handoffs[].agent` references resolve (matched case-sensitively); that an agent declaring `agents:` lists `'agent'` in its `tools`; that agent and skill `description` values and prompt `description`/`agent` values are single-line scalars (YAML block scalars `|`/`>` are rejected — the validator does not parse them); and that canonical cross-references (`` `instructions/...` ``, `` `skills/.../SKILL.md` ``, `` `agents/....agent.md` ``, `` `prompts/<name>.prompt.md` ``) point to real files — including inbound name-style prompt mentions (a backtick-wrapped lowercase name followed by the word "prompt", e.g. the `find-impact` prompt).

One-time local setup so the validator also runs on `git commit`:

```bash
git config core.hooksPath .githooks
```

`.githooks/pre-commit` runs the validator — against a snapshot of the staged index, not the working tree — only when staged paths match `.github/` markdown (pathspec `.github/*.md`, which in git's default semantics matches every depth including the top-level files; deletions count too, since removing a file is the change most likely to break cross-references), so unrelated commits aren't slowed down.

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
| Skills (10) | `.github/skills/<name>/SKILL.md` | Step-by-step workflow process (output templates embedded) | Description matches user intent, or `/skill-name` |
| Instructions (8) | `.github/instructions/*.instructions.md` | Single source of truth for coding conventions | A file matching `applyTo` glob is explicitly in context at request time (e.g. via `#file:`, editor attachment), or the model loads it on demand via semantic match on its `description` (discretionary); `applyTo: "**"` loads on every request |
| Prompts (4) | `.github/prompts/*.prompt.md` | Lightweight single-task shortcuts | Manual invocation (`/prompt-name`) |
| Hooks | `.github/hooks/default.json` + `scripts/` | Block dangerous shell commands pre-tool | Agent tool-use events |

**Critical separation-of-concerns rule:** each category has exactly one job. Content that belongs in another category must be **referenced**, not copied. Skills embed their own output templates directly. Instructions must not contain workflow content. Skills must not contain rule lists that duplicate instructions, save the two narrow exceptions noted below.

**Instruction loading model:** instructions reach the model through two channels, and only the first is deterministic. (1) **Glob injection at request time** — `applyTo` globs are matched against files explicitly in context (attached via `#file:`, editor attachment) and matching instruction files are auto-attached. Files the agent reads or edits dynamically during execution do NOT retroactively trigger glob instructions — the VS Code feature request to refresh instructions mid-session (microsoft/vscode#282964) was closed as not planned. (2) **On-demand semantic loading** — each request also carries a list of all instruction files (glob + `description`), and the model may choose to load one whose description matches the task; this is model-discretionary, never guaranteed. `applyTo: "**"` is the only guaranteed always-on glob. Because most skill invocations happen without an attached file and on-demand loading cannot be relied on, hard-boundary rules (Java 8 / Spring 3.2 / Hibernate 4.2 / SQL / security) are embedded directly in the code-touching agent bodies (`implementer`, `reviewer`, `debugger`) under `## Coding Standards` — these load deterministically when the agent is selected. Code-touching skills (`implement`, `refactor`, `code-review`, `sql-review`, `security-audit`, `debug`) additionally name the canonical instruction file(s) they map to, which the model opens on demand when it reads the skill body. The instruction files under `instructions/` remain the single source of truth; the agent-body embed is a deliberately minimal hard-boundary floor, not a full copy. **Two narrow duplications are sanctioned, both keeping the instruction file canonical:** (1) this version-lock hard-boundary embed in the code-touching agent bodies; and (2) skill verification checklists, self-verify gates, and one-line convention recaps inside workflow phases (e.g. `code-review`, `security-audit`, `sql-review`, `implement`), which may *name* canonical conventions as one-line check items but must not add detail beyond the instruction file. Keep both minimal; full rule restatement with added detail in a skill is a defect.

## Canonical Format — STYLE-GUIDE.md

`.github/STYLE-GUIDE.md` is the authoritative format spec for every file under `.github/`. Before adding or restructuring any agent / skill / instruction, read the matching skeleton in STYLE-GUIDE.md. Format changes to any category require updating STYLE-GUIDE.md **first**, then propagating to existing files.

Per-category key constraints (full rules in STYLE-GUIDE.md):

- **Instructions** — frontmatter is exactly `description` + `applyTo`. H1 is a descriptive title (no filename suffix). Anti-Patterns table is always 3-column `Pattern | Problem | Fix`.
- **Agents** — frontmatter requires `name`, `description`, `model`, `tools`. Body section order is fixed: `Coding Standards` (code-touching agents only) → `Skill Activation` → `Subagent Delegation` → `Workflow` → `Constraints` → `Handoff Guidance`.
- **Skills** — frontmatter is exactly `name` + `description`. **No `tools` field on skills** (tools belong on agents — validator enforces this). `description` is ≤ 1024 chars and follows the strict three-part format: `Use when …. Triggers on: …. <one-sentence summary>. Do NOT use for …`. H1 is always `<Name> — Workflow`. Skill `name` must match its directory name.
- **Prompts** — frontmatter is `agent` + `description`. Lightweight single-task shortcuts invoked via `/prompt-name`. Not output templates (those are embedded in skills).

## Cross-Reference Format

All cross-references use backtick-wrapped **relative paths from `.github/`**, never bare names:

| Type | Format |
|---|---|
| Instruction | `` `instructions/sql.instructions.md` `` |
| Skill | `` `skills/plan/SKILL.md` `` |
| Output template | Embedded in the paired `skills/<name>/SKILL.md` |
| Agent file | `` `agents/planner.agent.md` `` |
| Agent mention (in chat) | `` `@implementer` `` |
| Skill mention (inline) | `` `plan` skill `` |

## Maintenance Rule — Inbound Reference Check

The validator only enforces canonical path-style cross-references (`instructions/…`, `skills/…/SKILL.md`, `agents/….agent.md`, `prompts/….prompt.md`) and backtick-wrapped name-style prompt mentions, and it only scans files under `.github/` — `@agent` mentions, inline skill names, and references from root files (`README.md`, `AGENTS.md`) are not checked. Before renaming or moving any file under `.github/`, scan for inbound references:

```bash
grep -rn "<old-filename>" .github/
```

Broken paths silently degrade Copilot output — they don't error, they just stop loading the referenced content.

When **deleting or merging** a file, the path grep alone is not enough — several places reference skills/prompts by *name* in hardcoded lists. Follow the sweep checklist in `.github/STYLE-GUIDE.md` → File Lifecycle → Removing or Merging Files.

## Maintenance Rule — Cache-Friendly Edits

Copilot's usage-based billing (since June 2026) reuses **prompt cache** at stable prefix boundaries (system prompt, tool definitions, then injected instruction / agent / skill content). A cache *read* costs ~10× less than fresh input; the first *write* costs ~25% more. Within a session these files sit in the cached prefix, so the practical cost lever is **cache hit rate, not file length**.

Because caching is prefix-based, editing one line invalidates that file's cached segment **and everything after it** — the next session pays a full cache-write to rebuild. So:

- **Batch edits to `instructions/`, `agents/`, and `skills/` — change once, decisively. Do not micro-tune for token count.** The input savings from a shorter file are near-zero once the prefix is cached; the cache-write churn from frequent edits costs more than it saves.
- Trimming a file for clarity or correctness is fine. Trimming *purely* to shave tokens is a net loss — the cache already neutralised that cost.
- Keep these files stable between releases; land prompt-engineering changes together rather than as a drip of small commits.

## Maintenance Rule — List Ordering

Lists in `README.md`, `README.zh-TW.md`, and this file follow one of two deliberate orders. Decide which kind of list you are touching before picking an insertion position:

- **Mirror lists** — anything that claims to reflect the filesystem or a complete catalog: the "What Copilot Loads" tree and the Skills / Prompts / Instructions reference tables. Order: directories first, then files, alphabetical at every level — exactly what the VS Code explorer and GitHub show, so the list can be verified against `ls` at a glance and new entries have a deterministic insertion point.
- **Narrative lists** — anything that teaches the pipeline: the How It Works category table and the Architecture table in this file (Agents → Skills → Instructions → Prompts → Hooks), the Agents table, and the Typical Workflow sections (planner → implementer → reviewer → debugger). Order follows the user journey / activation chain — the order itself is content; do not alphabetize.

Alphabetizing a narrative list destroys the story; hand-ordering a mirror list breaks at-a-glance verification.

## Bilingual Conventions

This repo intentionally mixes languages. Respect the split:

- **All `.github/` content** (instructions, agents, skills) — English, because Copilot may inject it into any user's prompt context.
- **README has two versions**: `README.md` (English) and `README.zh-TW.md` (Traditional Chinese). Keep them in sync when changing either.
- **`.github/copilot-instructions.md`** declares the downstream-user contract: respond in Traditional Chinese, but code/comments/identifiers in English. Do not mistake this for guidance on how to edit this repo.

## Hooks — Dangerous-Command Block List

`.github/hooks/scripts/block-dangerous-commands.sh` denies shell tool calls matching these patterns (case-insensitive, input is whitespace-normalised before matching; patterns never cross a command separator `|`/`;`/`&`, so one command's flags cannot trigger on a neighbouring command). It reads the command from `toolArgs` (camelCase surfaces — object or JSON-encoded string) with a `tool_input` fallback (VS Code PascalCase payload). The hook is **fail-closed** — empty/whitespace-only input, JSON parse errors, missing `jq`, a missing `toolArgs`/`tool_input` key, or a `grep` error during pattern matching → deny. Denials exit 0 **and** print `{"permissionDecision":"deny","permissionDecisionReason":"…"}` to stdout naming the matched category, so the agent can report why and self-correct — Copilot parses the stdout decision JSON only on exit 0, and exit 2 is reserved as a *non-blocking* warning (the command would run anyway); an unexpected script crash exits non-zero (not 2), which `preToolUse` treats as a fail-closed deny. Regression suite: `bash .github/hooks/scripts/test-block-dangerous-commands.sh` (also run in CI).

**Blocked categories:** `rm` with recursive+force flags — combined `-rf`/`-fr` (flags and target in either order, e.g. `rm "$DIR" -rf`) only when targeting the exact tokens `/`, `~`, `~/`, `.`, `..`, `./`, `../`, `*`, `./*` or any `$`-prefixed variable (subpaths like `/tmp/x`, `.cache`, `./build` are allowed), but split `-r -f`/`-f -r` (tolerating intervening flags and operands, e.g. `rm -r build -f`) and long `--recursive`/`--force` (anywhere in the `rm` command, including mixed short+long like `rm -r --force`) blocked unconditionally (any target); `find -delete` / `find -exec rm` / `find -execdir rm`; `--no-preserve-root`; `sudo`, `doas`, `pkexec` (token-anchored — caught even glued to a separator like `&&sudo`, while `visudo` is not); `DROP DATABASE/SCHEMA/TABLE/INDEX/VIEW/FUNCTION/PROCEDURE`; `TRUNCATE TABLE` only — the bare `TRUNCATE <table>` form (MySQL allows the `TABLE` keyword to be omitted) is intentionally left unblocked so the coreutils `truncate` binary stays usable, since false positives are worse than false negatives for this net; `DELETE FROM`; `git push --force` / `git push -f` / `git push +refspec` (`--force-with-lease` is allowed); `git reset --hard`; `git clean` with any flag combo containing `-f`, or `--force`; `chmod 777` (tolerating preceding flags, glued `-R777`, and long `--recursive`; the mode must be the exact token `0?777` — `1777` is allowed); `mkfs.`/`mkfs ` (the `mkfs.*` family binary or the bare dispatcher); `shred`; `wipefs`; `curl|sh` / `wget|bash` — only when a bare shell word (`sh`/`bash`/`zsh`/`dash`/`ash`/`ksh`) immediately follows the pipe, including pipe chains (`curl … | cat | sh`), while piping into `sha256sum`/`jq`/`grep` is allowed (a path-prefixed or wrapped shell like `| /bin/sh` or `| env sh` is NOT matched — this is a best-effort net, not a sandbox); `base64 -d|` (decode-pipe); `dd` with `if=` or `of=/dev/` in any operand order; `kill -9 -1`; fork bomb `:(){ ... }`.

This is a **last-resort safety net, not a sandbox** — blocklists are inherently bypassable via encoding, aliases, or variable indirection. Downstream repos should run agents in restricted-permission environments. If you genuinely need one of these in development, run it directly outside the agent — do not bypass the hook.

## Commit & PR Process

- Conventional Commits (see `.github/skills/git-commit/SKILL.md` for the type table — `feat` / `fix` / `docs` / `refactor` / `perf` / `test` / `build` / `ci` / `chore` / `revert`).
- The `git-commit` skill is marked `disable-model-invocation: true` and **must** be invoked explicitly via `/git-commit` — never auto-trigger.
- PR workflow per `CONTRIBUTING.md`: branch from `main`, follow `STYLE-GUIDE.md`, run the inbound-reference grep before renaming files, run `validate-style-guide.sh` locally.

## Agent Roster (for orientation)

| Agent | Model | Activates |
|---|---|---|
| `@planner` | Claude Opus 4.8 | `plan`, `tasks` |
| `@implementer` | GPT-5.3-Codex | `implement`, `refactor`, `test-design` |
| `@reviewer` | Claude Opus 4.8 | `code-review`, `security-audit`, `sql-review` |
| `@debugger` | Claude Sonnet 4.6 | `debug` |
| `@researcher` | GPT-5.4 mini | Read-only subagent invoked by `@planner` / `@implementer` / `@reviewer` |

When adding a new skill: pick the owning agent, list the skill in that agent's `Skill Activation` table, and add bidirectional Handoffs entries if it interacts with other skills.

## Dependencies

### External
- **GitHub Copilot** — the runtime that loads everything under `.github/`
- `bash` + `jq` — required by the validator and the dangerous-command hook (hook is fail-closed without `jq`)
- **GitHub Actions** — CI enforcement

<!-- MANUAL: Custom project notes can be added below -->
