# Copilot Configuration Style Guide

Canonical format for every file type under `.github/`. Format changes require updating this guide first, then all affected files in the same PR.

## Five Categories

| Category | Role | Responsibility |
|---|---|---|
| **Agent** | Router | Who I am, which workflows I activate, who I hand off to |
| **Skill** | Workflow | Step-by-step process; embeds its own output template when one is needed |
| **Instruction** | Rules | Single source of truth for coding conventions — referenced by workflows |
| **Prompt** | Shortcut | Lightweight single-task shortcuts invoked via `/prompt-name` |
| **Hook** | Lifecycle Guard | Block dangerous commands before agent tool execution |

```text
Hook (Guard) ──→ Agent (Router) ──activates──→ Skill (Workflow + Template) ──rules──→ Instruction
Prompt (Shortcut) ──manual /prompt-name──→ Standalone execution
```

Each category has ONE job. Content that belongs in another category is **referenced**, not copied. Two sanctioned duplications only (see `AGENTS.md`): the agent-body `## Coding Standards` version-lock floor, and one-line convention recaps inside skill checklists.

**Dependency direction** — allowed: Agent→Skill, Skill→Instruction, Skill→Skill (handoffs only), Instruction→Instruction, Skill→Agent (handoffs only), Skill/Agent→Prompt (suggested-shortcut mention). Forbidden: Instruction→Skill/Agent (rules are context-free), Prompt→Skill (prompts are leaves), Hook→anything (hooks inspect tool calls only). A prompt's `agent:` frontmatter declares execution context, not a dependency.

## Where does new content go?

| I want to... | Create |
|---|---|
| Add a coding convention | `instructions/<name>.instructions.md` |
| Add a new workflow | `skills/<name>/SKILL.md` (+ a row in the owning agent's Skill Activation table) |
| Add a new AI agent role | `agents/<name>.agent.md` |
| Add a lightweight shortcut | `prompts/<verb>-<object>.prompt.md` |
| Block a dangerous command | `hooks/scripts/<name>.sh` + register in `hooks/default.json` |

After creating any file: `grep -rn "<new-filename>" .github/` to verify inbound references resolve.

## Instructions (`instructions/*.instructions.md`)

Frontmatter is exactly `description` + `applyTo` (non-empty glob). The `description` is the model's selectability hint for on-demand loading — one dense line: domain, concrete triggers, where to defer.

- H1: descriptive title (no filename suffix)
- Body: H2 topic sections with rule bullets; files with ≤3 lines of content may omit H2
- Anti-Patterns table (optional): always 3-column `| Pattern | Problem | Fix |`
- Cross-references: backtick-wrapped relative paths from `.github/`, never bare names

## Agents (`agents/*.agent.md`)

Frontmatter requires `name`, `description`, `model`, `tools`; `agents` and `handoffs` only when applicable. An agent declaring `agents:` must include `'agent'` in `tools`.

- H1: `<Name> — <Role Subtitle>`
- Section order (include only applicable): `Coding Standards` (code-touching agents only) → `Skill Activation` → `Subagent Delegation` → `Workflow` → `Constraints` → `Handoff Guidance` (always last)
- The `## Coding Standards` floor is the deterministic version-lock embed — keep its bullets identical across code-touching agents and each bullet consistent with its canonical `instructions/` source (human-reviewed)
- Lightweight subagents (e.g. `researcher`) may use a minimal `Rules` + `Output Format` body
- Handoffs: `label` ≤12 chars (Chinese preferred), `agent` must match an existing agent name case-sensitively (a typo silently breaks the button), `prompt` one Chinese sentence starting with `請`, `send: false` default

## Skills (`skills/<name>/SKILL.md`)

Frontmatter is exactly `name` + `description` (+ optional `disable-model-invocation: true` for manual-only skills). **No `tools` field** — tools belong on agents. `name` must match the directory. `description` ≤ 1024 chars, strict three-part format:

```
Use when <trigger scenario>. Triggers on: <en keywords>, <zh keywords>.
<One-sentence summary>. Do NOT use for <exclusion> (prefer <other-skill>).
```

Manual-only skills instead use `⚠️ MANUAL ONLY — invoke ONLY via /<name>. NEVER auto-trigger. Use when <scenario>.` (markers exempted).

- Triggers: bilingual (EN + 繁中), verb phrases not nouns, ~3–5 per intent domain, no overlap with sibling skills on the same agent (`grep -i "<trigger>" .github/skills/*/SKILL.md`)
- H1: always `<Skill Name> — Workflow`
- Code-touching skills open with `## Phase 0 — Load canonical rules`: one short paragraph naming the specific `instructions/<name>.instructions.md` files to open before acting (glob auto-loading does not fire for files read mid-task)
- Workflow: `## Phase N — <Imperative Verb Phrase>`, numbered from 1
- Output Template: only for skills emitting fixed-shape artifacts (`plan`, `code-review`, `sql-review`, `implement` test-design mode) — embed the markdown skeleton in the skill
- Handoffs (last section, when present): downstream `→` only, never upstream `←` (reverse lookup: `grep -rn "→ \`<name>\`" .github/`)

## Prompts (`prompts/*.prompt.md`)

Frontmatter is `agent` + `description`. Filename `<verb>-<object>.prompt.md`. Body: one imperative sentence + a numbered checklist, no headings, <20 lines, English only, no skill/agent references (if output overlaps a skill, invoke the skill instead).

## Hooks (`hooks/`)

Scripts in `hooks/scripts/*.sh`, registered in `hooks/default.json` under `preToolUse`. Use `block-dangerous-commands.sh` as the reference implementation. Non-negotiable rules:

1. `#!/usr/bin/env bash` + `set -euo pipefail`
2. **Always exit 0** — deny travels as `{"permissionDecision":"deny","permissionDecisionReason":"…"}` on stdout. Never exit 2 to deny: Copilot treats exit 2 as a non-blocking warning and the command runs anyway. Other non-zero exits are crashes, treated fail-closed.
3. Input is JSON on stdin: camelCase surfaces send `toolName`/`toolArgs` (object or JSON-encoded string), VS Code sends `tool_name`/`tool_input`. Parse both with a `jq` fallback chain; `toolInput` does not exist.
4. Fail closed: empty stdin, missing `jq`, parse errors, missing args payload, and grep errors (rc ≥ 2) all deny.
5. `timeout` is a latency budget, not a safety control — on expiry the platform allows. Keep hooks fast.
6. No side effects — inspect and decide only.
7. Pattern design: `grep -qiE`; false positives are worse than false negatives — err toward allowing.
8. Run `bash .github/hooks/scripts/test-block-dangerous-commands.sh` after any hook change.

## Cross-Reference Format

Backtick-wrapped relative paths from `.github/`: `` `instructions/sql.instructions.md` ``, `` `skills/plan/SKILL.md` ``, `` `agents/planner.agent.md` ``, `` `prompts/find-impact.prompt.md` `` — all CI-validated to resolve. Inline mentions (`` `@implementer` ``, `` `plan` skill ``) are not machine-checked — verify in PR review.

## Validation

### Machine-checked (`validate-style-guide.sh`, enforced in CI and the opt-in pre-commit hook)

- Instruction frontmatter: non-empty `description` + `applyTo`
- Skill frontmatter: `name` + `description` present; `name` matches directory; `description` ≤ 1024 chars with required markers (`Use when`, `Triggers on:`, `Do NOT use` — exempted for manual-only skills); no `tools` field
- Prompt frontmatter: `agent` + non-empty `description`
- Agent frontmatter: `name`, `description`, `model`, `tools` present; `handoffs[].agent` values resolve to existing agent names
- All canonical path cross-references resolve to existing files

### Human review (PR checklist)

- [ ] H1 follows the category convention; phase headings are imperative
- [ ] Agent `## Coding Standards` bullets identical across code-touching agents and consistent with their `instructions/` sources
- [ ] No content duplicated across categories beyond the two sanctioned exceptions
- [ ] Handoffs downstream-only; inline `@agent` / skill mentions reference real entities
- [ ] New triggers don't overlap sibling skills on the same agent
- [ ] README.md and README.zh-TW.md stay in sync

## File Lifecycle

**Rename/move**: `grep -rn "<old-filename>" .github/` → update all references + README tables in the same PR → run the validator.

**Remove/merge**: a filename grep misses name-style references. Sweep in the same PR: (1) name grep across `.github/ README.md README.zh-TW.md AGENTS.md`; (2) enumerated lists in this file and `AGENTS.md`; (3) both READMEs' tables and trees; (4) sibling `Do NOT use for … (prefer <name>)` clauses; (5) `→` handoff lines in other skills/agents; (6) the owning agent's Skill Activation table (re-route triggers when merging); (7) run the validator. Broken paths silently degrade Copilot output — they do not error.

**Edit**: injected context must stay lean and stable — batch edits decisively into one atomic PR (see `AGENTS.md`).
