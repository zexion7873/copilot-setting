# Copilot Configuration Style Guide

Canonical format for every file type under `.github/`. All files MUST follow these skeletons. Format changes require updating this guide first.

## Five Categories

| Category | Role | Responsibility |
|---|---|---|
| **Agent** | Router | Who I am, which workflows I activate, who I hand off to |
| **Skill** | Workflow | Step-by-step process — embeds its own output template when one is needed (see skill rule 9); references Rules rather than restating them (verification checklists may *name* conventions as check items only) |
| **Instruction** | Rules | Single source of truth for coding conventions — referenced by workflows |
| **Prompt** | Shortcut | Lightweight single-task shortcuts invoked via `/prompt-name` |
| **Hook** | Lifecycle Guard | Block dangerous commands before agent tool execution |

```text
Hook (Guard) ──lifecycle guard──→ Agent (Router) ──activates──→ Skill (Workflow + Output Template)
                                                                       │
                                                                       └──rules──→ Instruction (Rules)

Prompt (Shortcut) ──manual /prompt-name──→ Standalone execution
```

Each category has ONE job. Content that belongs in another category MUST be delegated, not copied. See the **Dependency Direction** section for enforcement rules.

---

## Decision Tree

Use this table to determine which file to create or modify.

| I want to... | Create | Where |
|---|---|---|
| Add a coding convention | Instruction | `instructions/<name>.instructions.md` |
| Add a new workflow | Skill | `skills/<name>/SKILL.md` (embed output template if needed) |
| Add a new AI agent role | Agent | `agents/<name>.agent.md` |
| Add a lightweight shortcut | Prompt | `prompts/<verb>-<object>.prompt.md` |
| Block a dangerous command | Hook script | `hooks/scripts/<name>.sh` + register in `hooks/default.json` |
| Add a review mode to @reviewer | Skill + agent table row | `skills/<name>/SKILL.md` + `agents/reviewer.agent.md` Skill Activation table |
| Add a build mode to @implementer | Skill + agent table row | `skills/<name>/SKILL.md` + `agents/implementer.agent.md` Skill Activation table |

After creating any file, verify inbound references resolve: `grep -rn "<new-filename>" .github/`.

---

## Dependency Direction

References between categories must follow allowed directions. This prevents circular dependencies and keeps each category's scope clean.

### Content dependencies (what the file NEEDS to function)

```text
Agent ──activates──→ Skill (embeds output template)
                       │
                       └──applies rules from──→ Instruction
```

| From | To | Allowed? | Example |
|---|---|---|---|
| Agent → Skill | ✅ | Skill Activation table: `skill-name` |
| Skill → Instruction | ✅ | "Rules live in `instructions/sql.instructions.md`" |
| Skill → Skill | ✅ | Handoffs section only: `→ code-review skill` |
| Instruction → Instruction | ✅ | Cross-reference related rules: `instructions/java.instructions.md` |

### Navigational back-references (pointing readers to context)

| From | To | Allowed? | Purpose |
|---|---|---|---|
| Skill → Agent | ✅ | Handoffs section only: "suggest `@reviewer`" |
| Skill/Agent → Prompt | ✅ | Suggested-shortcut mention only — backtick-wrapped name followed by the word "prompt" (e.g. the `find-impact` prompt); CI validates it resolves to `prompts/<name>.prompt.md` |

### Forbidden directions

| From | To | Why |
|---|---|---|
| Instruction → Skill | ❌ | Rules must not know about workflows — they are consumed, not consumers |
| Instruction → Agent | ❌ | Rules must not know who executes them — they are context-free conventions |
| Prompt → Skill | ❌ | Prompts are standalone shortcuts; if output overlaps a skill, invoke the skill instead |
| Hook → Skill/Agent/Instruction | ❌ | Hooks inspect tool calls only — they have no knowledge of the agent/skill graph |

> **Note on Prompt `agent` frontmatter:** the `agent:` field in prompt frontmatter declares execution context (which agent runs the prompt), not a content dependency. Prompt **body** must not reference skill files or agent files.

---

## Instructions (`instructions/*.instructions.md`)

### Frontmatter (required fields)

```yaml
---
description: '<Selectability hint — when should the model pull THIS file for the task? Domain, then concrete triggers (task contexts, co-occurring symbols, version-lock negatives), then where to defer. One dense line; it ships into every VS Code request.>'
applyTo: '<glob pattern>'
---
```

### Body Skeleton

```markdown
# <Descriptive Title>

<Scope statement (1–2 sentences). Use "Hard rules for..." when the file defines non-negotiable conventions; otherwise, start with a direct statement of what this file covers.> Cross-reference related files using relative paths from `.github/`: e.g., `instructions/sql.instructions.md`.

## <Topic Section>

- Rule items as bullet lists
- Reference tables where appropriate

## Anti-Patterns

| Pattern | Problem | Fix |
|---|---|---|
| `bad code` | Why it's wrong | `good code` or description |

## Checklist

- [ ] Verification item (optional section — include only when the instruction benefits from a self-check list)
```

### Rules

1. **Frontmatter**: `description` + `applyTo` — both required, no other fields. `applyTo` must be a non-empty glob pattern (e.g., `**/*.java`). An invalid glob silently prevents the instruction from loading. The `description` is the model's **selectability hint** for on-demand semantic loading — VS Code passes every instruction's description into each request so the model can self-select which to load. Write it to signal *whether to load THIS file for THIS task*: lead with the domain, then concrete triggers (task contexts, co-occurring symbols, version-lock negatives), then where to defer to a sibling. Keep it one dense line — it ships into every VS Code request, so high signal-to-noise beats an exhaustive token list.
2. **H1**: descriptive title. No filename suffix, no category prefix.
3. **Opening paragraph**: scope statement + cross-references to related instruction files (if any). Use full relative paths from `.github/` (e.g., `instructions/security.instructions.md`), not bare names.
4. **Body sections**: H2 for topic grouping. Use bullet lists for rules, tables for quick-reference lookups. **Exception**: files with ≤3 lines of content (e.g., `no-heredoc`) may omit H2 sections.
5. **Anti-Patterns table**: always 3-column (`Pattern | Problem | Fix`). If the file has anti-patterns, use this exact header. Column 2 (`Problem`) must explain *why* it's wrong, not just restate the pattern.
6. **Checklist section**: optional. Use only when the instruction benefits from a verification self-check (e.g., markdown formatting, commenting guidelines). Use `- [ ]` checkbox format.
7. **Cross-references**: use backtick-wrapped relative paths from `.github/` — e.g., `` `instructions/sql.instructions.md` ``. Never use bare names like `` `sql` `` or absolute paths.

---

## Agents (`agents/*.agent.md`)

### Frontmatter (required fields)

```yaml
---
name: <AgentName>
description: '<Role summary — what this agent does and who it hands off to.>'
model: <Model Name>
tools: ['tool1', 'tool2']
agents: ['SubagentName']          # optional — only if this agent delegates to subagents
handoffs:                          # optional — only if this agent has handoff buttons
  - label: <Button Label>
    agent: <TargetAgent>
    prompt: <Handoff prompt text>
    send: false
---
```

### Body Skeleton

```markdown
# <Name> — <Role Subtitle>

<Role description (1–2 sentences). Tech stack context (e.g., "Java 8 / Maven projects"). Ambiguity-handling stance (e.g., "ask clarifying questions before planning").>

## Coding Standards

<Code-touching agents only. Hard-boundary coding rules the agent must enforce on every change.>

## Skill Activation

| Trigger | Skill | Output |
|---|---|---|
| "keyword", "關鍵字" | `skill-name` | What it produces |

Default to `<default-skill>` if the user's intent is ambiguous but clearly <domain>-related.

## Subagent Delegation

<When and how to delegate to subagents. What to ask for, what NOT to ask for.>

Skip delegation when <condition>.

## Constraints

- Constraint items (if applicable)

## Handoff Guidance

- <condition> → suggest `@agent`
```

### Rules

1. **Frontmatter**: `name`, `description`, `model`, `tools` — all required. `agents` and `handoffs` — include only when applicable.
2. **H1**: `<Name> — <Role Subtitle>`. Subtitle describes the specialist domain (e.g., "Technical Planning & Specification Specialist").
3. **Opening paragraph**: role description + tech stack context + ambiguity stance.
4. **Section order** (include only applicable sections, but maintain this order):
   - `Coding Standards` — hard-boundary coding rules (code-touching agents only)
   - `Skill Activation` — table of trigger → skill → output (all agents that activate skills must have this)
   - `Subagent Delegation` — delegation instructions
   - `Workflow` — process description (only if not fully covered by skills)
   - `Constraints` — constraints list
   - `Handoff Guidance` — when to hand off to other agents (always last body section)
5. **Lightweight agents** (subagents like `researcher`): may use a minimal structure (`Rules` + `Output Format`) instead of the full skeleton. Frontmatter must still be complete.
6. **Handoff target validation**: every `handoffs[].agent` value must match an existing agent `name` (case-sensitive). A typo silently breaks the VS Code handoff button — there is no runtime error.
7. **Handoff format** (when `handoffs` is present in frontmatter):
   - `label`: short imperative phrase (≤ 12 characters; CJK labels are typically 4–5 glyphs). Chinese preferred for consistency with `copilot-instructions.md` response language; English acceptable for widely recognized terms (e.g., `Code Review`).
   - `agent`: must reference an existing agent `name` (case-sensitive).
   - `prompt`: one sentence in Chinese, starts with `請`. Provides context for the receiving agent.
   - `send: false` is the default — the user confirms before handoff is sent. Use `send: true` only for fully automated handoffs (none currently exist).

---

## Skills (`skills/*/SKILL.md`)

### Frontmatter (required fields)

```yaml
---
name: <skill-name>
description: '<Three-part description following the structure below.>'
disable-model-invocation: true    # optional — manual-only skills (invoked solely via /<skill-name>)
---
```

### Description Format (strict)

The `description` field MUST follow this three-part structure:

```
Use when <trigger scenario — what the user is asking for>.
Triggers on: <en-keyword-1>, <en-keyword-2>, <zh-keyword-1>, <zh-keyword-2>.
<One-sentence summary of what the skill produces.>
Do NOT use for <exclusion-1> (prefer <alternative-skill>), <exclusion-2> (prefer <alternative-skill>).
```

For manual-only skills (`disable-model-invocation: true`), the entire description is:

```
⚠️ MANUAL ONLY — invoke ONLY via /<skill-name>. NEVER auto-trigger.
Use when <trigger scenario>.
```

`Triggers on:` and `Do NOT use for` are omitted — trigger keywords are meaningless for a skill that never auto-triggers; the validator exempts all three markers for these skills (see Tier 1).

### Trigger Keyword Design

Guidelines for the `Triggers on:` section in skill descriptions and the corresponding agent Skill Activation table.

- Include both **English AND Chinese** triggers (bilingual user base per `copilot-instructions.md`).
- **4–10 trigger phrases per intent domain.** A single-domain skill therefore stays within 4–10 total. A skill that absorbed a sibling's domain in a merge (e.g. `sql-review` covers both queries and migrations, `plan` covers planning and clarification) may exceed 10 total, but each domain's phrase set must individually stay within 4–10 and the overage must be justified in the PR. Too few = missed intent; every extra phrase widens the false-activation surface (the sibling-overlap grep below catches only literal overlap, not semantic near-misses) and enlarges the agent Skill Activation mirror, which the validator does not check and which has already drifted once. The 1024-char description cap is a platform limit, not a design budget — remaining headroom is not licence to add triggers.
- Use **verb phrases**, not bare nouns: `"review SQL"` not `"SQL"`.
- Include common **variations and synonyms**: `"怎麼做"` and `"幫我想方案"` for the same skill.
- **No overlap with sibling skills** on the same agent. If a phrase could activate 2 skills, the agent's Skill Activation section must specify a default (e.g., "Default to `implement` if ambiguous").
- Overlap between skills on **different agents** is acceptable — the user's `@agent-name` choice disambiguates.
- **Before adding or changing triggers**, grep sibling skills on the same agent to confirm no overlap: `grep -i "<new-trigger>" .github/skills/*/SKILL.md`.

### Body Skeleton

```markdown
# <Skill Name> — Workflow

<What this skill does (1–2 sentences). Cross-reference to instruction files that define rules.> Non-code-touching skills omit the Phase 0 block below.

## Phase 0 — Load canonical rules

<MANDATORY pre-load gate (rule 4) — the leading step for code-touching skills: open the named instruction file(s) before any code-touching phase. The agent-body `## Coding Standards` bullets are a floor, not the full rules.>

- `instructions/<name>.instructions.md` — <what this file covers>
- `instructions/<name>.instructions.md` — <what this file covers>

Read-back receipt (required): before leaving this step, NAME each instruction file you opened above and QUOTE the single most load-bearing rule from each that applies to this change — a generic restatement proves you did not open it.

## Phase 1 — <Verb Phrase>

<Phase content — instructions, bash commands, tables, etc.>

## Phase N — <Verb Phrase>

<Phase content>

## Rules

- Rule items specific to this skill's workflow

## Output Template

<CONDITIONAL — only for skills emitting a fixed-shape structured artifact (plan, tasks, code-review, sql-review). The deterministic markdown skeleton the skill produces.>

## Anti-Patterns

- <Anti-pattern description> → <consequence or fix>

## Handoffs

- → `<skill>` skill — <when to hand off downstream>
- ← `<skill>` skill — <when this skill receives handoff from upstream>
```

### Rules

Each rule is marked **REQUIRED**, **CONDITIONAL**, or **OPTIONAL**.

1. **Frontmatter** (**REQUIRED**): `name` + `description` — both required. The only optional field is `disable-model-invocation: true`, for manual-only skills that must never auto-trigger (e.g., `git-commit`). No `tools` in skill frontmatter (tools belong on agents).
2. **H1** (**REQUIRED**): always `<Skill Name> — Workflow`. No variation (`Executable Workflow`, `Overview`, etc.). No exceptions — even the reference+process hybrids (`refactor`, `git-commit`), which are exempt from Phase sections below, use this exact H1.
3. **Opening paragraph** (**REQUIRED**): what + cross-references. Name the specific instruction file(s) the skill relates to (e.g., `sql-review` → `instructions/sql.instructions.md`). The instruction-reference block (rule 4) carries the full per-skill set — do not use the `instructions/*.instructions.md` glob to stand in for it.
4. **Instruction reference block** (**CONDITIONAL** — code-touching skills only): required for skills that modify or review code (`implement`, `refactor`, `code-review`, `sql-review`, `security-audit`, `debug`). It lives inside the leading `## Phase 0 — Load canonical rules` section (rule 5) and names the canonical instruction file(s) the skill maps to as a bullet list of `instructions/<name>.instructions.md` references — name specific files, not the `*` glob, so an agent with file access can open them directly. Phase 0 closes with a read-back receipt: the agent must NAME each file it opened and QUOTE the single most load-bearing applicable rule from each. Each skill lists only the instruction files relevant to its domain (broad skills like `implement` name all; narrow skills like `sql-review` name just theirs). The hard-boundary rules previously duplicated in an inline condensed floor now live in the code-touching agent bodies under `## Coding Standards`.
5. **Phase sections** (**REQUIRED** unless excepted): `## Phase N — <Verb Phrase>`. Verb phrase uses imperative mood (e.g., "Understand Before Writing", "Classify Findings", "Map the Attack Surface"). Numbered sequentially from 1. **Phase 0 exception**: a code-touching skill's mandatory pre-load gate (rule 4) is its leading workflow step, rendered as `## Phase 0 — Load canonical rules` (the only sanctioned `## Phase 0`) immediately before `## Phase 1`. **Exception**: skills that are inherently reference guides with embedded process (`refactor`, `git-commit`) — where Phase N format would damage readability — may use topic-based H2 sections instead, and render the pre-load gate as a bare leading `## Load canonical rules` H2.
6. **Rules section** (**OPTIONAL**): include when the skill has rules specific to its own workflow that aren't covered by instruction files. Not a repeat of instruction-level rules. Omit rather than add an empty section.
7. **Handoffs section** (**CONDITIONAL** — required if the skill hands off to or receives from other skills/agents): use `→` for downstream (this skill hands off to) and `←` for upstream (this skill receives from). Reference by skill name in backticks and agent name with `@` prefix. When present, Handoffs is always the last body section (mirroring agent rule 4's Handoff Guidance placement).
8. **Anti-Patterns section** (**OPTIONAL**): include when the skill has common misuse patterns. Format as a bullet list with `→` separator, or as a paragraph if context-heavy.
9. **Output Template section** (**CONDITIONAL**): required for skills that produce structured artifacts with a fixed shape — currently `plan`, `tasks`, `code-review`, `sql-review`. Skills whose output is code, free-form prose, or context-dependent (`implement`, `refactor`, `debug`, `security-audit`, `test-design`, `git-commit`) do not need this section — their workflow phases, self-verify checklists, or finding-format conventions are sufficient. When adding a new skill, decide by output shape: deterministic markdown skeleton → include the section; per-task variable output → omit.
10. **Subfiles** (**OPTIONAL**): skills may keep supporting files (examples, reference data) in subdirectories under the skill folder. Subfiles carry no frontmatter (they are not skills and are never auto-triggered), and the parent `SKILL.md` must reference them by relative path (e.g., `examples/<topic>.md`). No skill currently ships subfiles — spec a full skeleton if and when they return.

---

## Prompts (`prompts/*.prompt.md`)

Standalone single-task shortcuts the user invokes via `/<prompt-name>`. A prompt **body** must not reference skills or agents (a prompt is a leaf of the graph), but a skill or agent **may** name a prompt as a suggested shortcut (e.g. the `find-impact` prompt) — that inbound mention is allowed and is validated to resolve.

### Frontmatter (required fields)

```yaml
---
agent: 'agent'
description: '<One-sentence task description starting with an imperative verb.>'
---
```

### Body Skeleton

```markdown
<Imperative task statement — one sentence telling the agent what to do.>

1. **<Aspect>**: <What to check/produce for this aspect>
2. **<Aspect>**: <What to check/produce for this aspect>
3. **<Aspect>**: <What to check/produce for this aspect>
```

Body is a flat checklist or numbered instruction list. No H1/H2 headings, no phase structure (that belongs in skills). Keep it scannable — the agent reads it as a single directive.

### Rules

1. **Filename pattern** (**REQUIRED**): `<verb>-<object>.prompt.md`. Verb first, lowercase, hyphen-separated. Examples: `check-tx`, `find-impact`, `generate-migration-sql`. Reject noun-first or noun-only names.
2. **No skill references** (**REQUIRED**): prompts must not link to `skills/*/SKILL.md`. If output overlaps with a skill, invoke the skill instead — do not duplicate.
3. **Body language** (**REQUIRED**): English. Per `copilot-instructions.md`, prompts may be injected into any user's context.
4. **Body structure** (**REQUIRED**): starts with one imperative sentence, followed by a numbered list of aspects/checks. No Markdown headings (`#`, `##`). No phase-based workflow structure.
5. **Length** (**REQUIRED**): keep prompt body under 20 lines. Longer workflows belong in a skill.

---

## Hooks (`hooks/`)

Lifecycle guards that intercept agent tool calls before execution. Hooks inspect — they never modify files or produce output for the user.

### Configuration (`hooks/default.json`)

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "bash": "bash .github/hooks/scripts/<script-name>.sh",
        "timeout": 5
      }
    ]
  }
}
```

### Script Skeleton (`hooks/scripts/*.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Deny reasons must not contain double quotes or backslashes — they are
# embedded verbatim into the stdout JSON.
# Must exit 0: the decision JSON is only parsed on exit 0; exit 2 would
# downgrade the deny to a non-blocking warning and the command would run.
deny() {
  printf '{"permissionDecision":"deny","permissionDecisionReason":"%s"}\n' "$1"
  echo "DENY: $1" >&2
  exit 0
}

INPUT=$(cat)

# Empty / whitespace-only stdin → deny (fail-closed; without this gate the
# skeleton run verbatim ALLOWS empty input).
if [ -z "${INPUT//[[:space:]]/}" ]; then
  deny "empty input (fail-closed)"
fi

TOOL_NAME=$(jq -r '.toolName // .tool_name // ""' <<<"$INPUT") \
  || deny "unparseable input (fail-closed)"

# Filter by tool type — fail-closed: fast-path allow known read-only tools,
# all other (incl. unknown) tools fall through to deny-pattern inspection
case "$TOOL_NAME" in
  read_file|list_dir|list_directory|search|grep|codebase|read|find_files) exit 0 ;;
  *) ;;
esac

# The args payload must exist under one of the documented keys; its absence
# means the hook schema changed under us → deny rather than inspect nothing.
HAS_ARGS=$(jq 'has("toolArgs") or has("tool_input")' <<<"$INPUT") \
  || deny "unparseable input (fail-closed)"
if [ "$HAS_ARGS" != "true" ]; then
  deny "missing toolArgs/tool_input payload (fail-closed)"
fi

# camelCase surfaces (Copilot CLI, cloud agent) send toolArgs — an object
# or a JSON-encoded string; the VS Code PascalCase payload sends tool_input.
# Cover the command-ish keys (.command/.cmd/.script) and join argv arrays.
CMD=$(jq -r '(.toolArgs // .tool_input // "")
  | if type == "string" then (fromjson? // .) else . end
  | if type == "object" then (.command // .cmd // .script // "") else . end
  | if type == "array" then join(" ") else tostring end' <<<"$INPUT") \
  || deny "unparseable input (fail-closed)"

# Deny patterns (case-insensitive)
DENY_PATTERNS="<pipe-separated regex patterns>"

RC=0
grep -qiE "$DENY_PATTERNS" <<<"$CMD" || RC=$?
if [ "$RC" -eq 0 ]; then
  deny "<reason>"
elif [ "$RC" -ge 2 ]; then
  deny "pattern match error (fail-closed)"
fi

exit 0
```

### Rules

1. **Shebang**: `#!/usr/bin/env bash` on line 1.
2. **Error handling**: `set -euo pipefail` on line 2.
3. **Exit codes**: always exit `0` — the decision travels on stdout, which Copilot parses as hook output JSON *only* on exit 0. Deny = print `{"permissionDecision":"deny","permissionDecisionReason":"…"}` to stdout and exit `0` (the agent sees *why* and can self-correct); allow = exit `0` with no decision JSON. **Never exit `2` to deny** — Copilot treats exit 2 as a non-blocking warning and the tool call proceeds. Any other non-zero exit signals a script error, which `preToolUse` handles fail-closed (denied, but without a readable reason); the stderr line is only for human log readability.
4. **Input format**: JSON on stdin. camelCase surfaces (Copilot CLI, cloud agent) send `toolName` (string) and `toolArgs` (object **or JSON-encoded string** — unwrap with `fromjson?`); the VS Code PascalCase payload sends `tool_name` and `tool_input`. Parse with `jq` fallback chains covering both shapes (see the skeleton). The field `toolInput` does not exist in any payload format — reading it silently yields an empty string and the hook inspects nothing.
5. **Tool filtering**: always check `TOOL_NAME` first. This repo's hook is **fail-closed** (see the dangerous-command block-list section in `AGENTS.md`): known read-only tools (`read_file`, `list_dir`, `search`, …) `exit 0` immediately, and every other tool — including unknown ones — falls through to deny-pattern inspection. The deny patterns only match shell command strings, so non-shell tools that fall through are allowed in practice while no unknown tool is blanket-skipped. A plain allowlist (`exit 0` for everything non-shell) is also acceptable for less safety-critical hooks.
6. **Timeout**: `timeout` (the field name `default.json` uses) bounds how long the platform waits for the hook — on expiry the fallback is **allow, not deny**: a timed-out blocking hook is silently bypassed and a late deny is discarded (github/copilot-cli#2893; hook dispatch is also serialized under parallel tool calls, so queue delay eats the budget). Treat the timeout as a latency budget, never a safety control. Keep hooks fast — they run on every tool call — and keep `timeout` ≤ 30 (the platform default) so a hung hook cannot stall tool calls, but do not set it aggressively low on a blocking hook.
7. **No side effects**: hooks inspect input and allow/deny. They must not modify files, write to the workspace, or produce user-visible output (except the deny-decision JSON on stdout and the log line on stderr).
8. **Pattern matching**: use `grep -qiE` (case-insensitive extended regex) for deny patterns. When deciding what a pattern should match, false positives are worse than false negatives — err on the side of allowing (see the `TRUNCATE TABLE` decision in the dangerous-command block-list section of `AGENTS.md` for a worked example). This trade-off governs pattern design only; a grep error during matching (RC ≥ 2) stays fail-closed, as in the skeleton.

---

## Cross-Reference Format (all categories)

| Reference type | Format | Example | Validated? |
|---|---|---|---|
| Instruction file | `` `instructions/<name>.instructions.md` `` | `` `instructions/sql.instructions.md` `` | ✅ CI |
| Instruction glob (all) | `` `instructions/*.instructions.md` `` | Avoid in skills — name specific files in the instruction-reference block instead | ❌ |
| Skill file | `` `skills/<name>/SKILL.md` `` | `` `skills/plan/SKILL.md` `` | ✅ CI |
| Agent file | `` `agents/<name>.agent.md` `` | `` `agents/planner.agent.md` `` | ✅ CI |
| Prompt file | `` `prompts/<name>.prompt.md` `` | `` `prompts/find-impact.prompt.md` `` | ✅ CI |
| Agent mention | `` `@agent-name` `` | `` `@implementer` `` | ❌ |
| Skill mention (inline) | `` `skill-name` `` or `` `skill-name` skill `` | `` `plan` skill `` | ❌ |
| Prompt mention (name-style) | `` `<name>` `` followed by the word "prompt" | the `` `find-impact` `` prompt | ✅ CI |
| Global instructions | `` `copilot-instructions.md` `` | `` `copilot-instructions.md` `` | ❌ |

All paths are relative from `.github/`. Never use bare names without context (e.g., `` `sql-rules` `` alone) — always include enough path to be unambiguous.

The **Validated?** column indicates whether `validate-style-guide.sh` automatically checks that the referenced file exists. References marked ❌ require manual verification during PR review.

---

## Validation Tiers

What is machine-checked vs. what requires human review.

### Tier 1: Machine-checked (`validate-style-guide.sh` + CI)

These are enforced automatically on every PR that touches `.github/**/*.md`, the validator script, `.github/hooks/**`, or the workflow file.

- Instruction frontmatter has `description` + `applyTo`
- Instruction `applyTo` value is non-empty
- Skill frontmatter has `name` + `description`
- Skill `name` matches its parent directory name
- Skill `description` ≤ 1024 characters
- Skill `description` contains required markers (`Use when`, `Triggers on:`, `Do NOT use`) — exempted for `disable-model-invocation: true` skills
- No `tools` field in skill frontmatter
- Prompt frontmatter has `agent` + `description`
- Agent frontmatter has `name`, `description`, `model`, `tools`
- Agent `description` is a single-line scalar (no YAML block scalars `|`/`>` — the validator does not parse them)
- Skill `description` and prompt `description`/`agent` values are single-line scalars (same rule)
- Agent `handoffs[].agent` values reference existing agent names
- Agent declaring `agents:` in frontmatter includes `'agent'` in its `tools` list (subagent delegation requires the `agent` tool)
- Instruction Anti-Patterns tables use 3-column format (`Pattern | Problem | Fix`)
- Code-touching skills name at least one specific `instructions/<name>.instructions.md` file (not only the `*` glob)
- Code-touching agents (`implementer`, `reviewer`, `debugger`) embed a `## Coding Standards` section, and its hard-boundary bullets (lines starting with `- `) are byte-identical across all three agents — the comparison covers only those `- ` lines; non-bullet prose (e.g. the per-agent intro sentence) is never compared and may differ, so prose drift is a Tier-2 human check; those bullets must be top-level `- ` items — indented sub-bullets, `*`/`+` bullets, or numbered lines, which would escape the byte-identity comparison, are rejected
- All canonical cross-references (`` `instructions/...` ``, `` `skills/...` ``, `` `agents/...` ``) resolve to existing files. Inbound prompt mentions (a skill or agent naming a prompt, e.g. the `find-impact` prompt) are also checked to resolve to a real `prompts/<name>.prompt.md`.

### Tier 2: Human-review (PR review checklist)

These require manual verification. Reviewers should check:

- [ ] H1 follows category naming convention
- [ ] Agent `## Coding Standards` floor covers the version-lock essentials (Java 8 / Spring 3.2 / Hibernate 4.2 / SQL / security) and each bullet still matches its canonical `instructions/` source of truth per the **Floor ↔ Instruction map** below — the validator cross-checks byte-equality between agents, but never against `instructions/`, so this human check is the only guard against floor↔source drift
- [ ] Phase sections use imperative verb phrases
- [ ] No duplicated content across categories — two sanctioned exceptions only: (1) the agent-body `## Coding Standards` embed, and (2) skill verification checklists, self-verify gates, and one-line convention recaps inside workflow phases, which may *name* canonical conventions as one-line check items but add no detail beyond the instruction file — full rule restatement with added detail remains a defect (see AGENTS.md "Two narrow duplications")
- [ ] Handoff sections are bidirectional (if A → B, then B ← A)
- [ ] Agent Skill Activation table matches the skills that reference that agent
- [ ] Dependency direction rules are respected (see **Dependency Direction** section)
- [ ] Inline skill/agent mentions (`` `@agent` ``, `` `skill-name` ``) reference real entities
- [ ] New/modified trigger keywords do not overlap with sibling skills on the same agent
- [ ] Skills producing structured artifacts have `## Output Template` section (plan, tasks, code-review, sql-review)

**Floor ↔ Instruction map** (supports the Coding Standards checklist item above) — each agent `## Coding Standards` bullet is a condensed paraphrase of a canonical rule, not a verbatim copy, so the validator cannot byte-check it against `instructions/`; this pairing is human-verified. When you change a floor bullet or its source, re-check the pair:

| Agent `## Coding Standards` bullet | Canonical `instructions/` source |
|---|---|
| `**Java 8**` | `instructions/java.instructions.md` |
| `**Spring 3.2**` | `instructions/spring-hibernate.instructions.md` (Spring 3.2 Boundary) |
| `**Hibernate 4.2**` | `instructions/spring-hibernate.instructions.md` (Hibernate) |
| `**SQL**` | `instructions/sql.instructions.md` (JDBC `?` + HQL `:paramName`) |
| `**Security**` | `instructions/jsp.instructions.md` (`<c:out>` encoding) + `instructions/security.instructions.md` (A07 cookie flags) |
| `**Access Control (A01)**` | `instructions/security.instructions.md` (A01) |
| `**Deserialization (A08)**` | `instructions/security.instructions.md` (A08) |
| `**SSRF (A10)**` | `instructions/security.instructions.md` (A10) |

---

## File Lifecycle

### Renaming or Moving Files

1. Scan for inbound references: `grep -rn "<old-filename>" .github/`
2. Update all references + README tables in the same PR.
3. Run validator: `bash .github/scripts/validate-style-guide.sh`

### Removing or Merging Files

Deleting or merging a skill / prompt / agent has touchpoints a filename grep will NOT find — they reference the entity by *name*, not by path. Sweep all of these in the same PR:

1. Name grep across product and root docs: `grep -rn "<name>" .github/ README.md README.zh-TW.md AGENTS.md`
2. Hardcoded skill lists in the validator (`scripts/validate-style-guide.sh`, e.g. `INSTRUCTION_REF_SKILLS`).
3. Enumerated skill lists in this file: the instruction-reference rule, the Output Template rule, and the review checklist.
4. `AGENTS.md`: Architecture table category counts, the instruction-loading-model skill lists, and the Agent Roster table.
5. `README.md` + `README.zh-TW.md` (keep in sync): agent table, Typical Workflow tables, Skills / Prompts tables, and the "What Copilot Loads" tree.
6. Sibling skill descriptions: `Do NOT use for … (prefer <name>)` clauses pointing at the removed entity.
7. Handoffs sections in other skills and agents: delete dead `→` / `←` lines; keep the surviving pairs bidirectional.
8. The owning agent's Skill Activation table; when merging, re-route the removed skill's trigger phrases to the absorbing skill.
9. Run validator: `bash .github/scripts/validate-style-guide.sh`

Broken paths silently degrade Copilot output — they do not error.

### Editing Existing Files (Batch Decisively)

`instructions/` / `agents/` / `skills/` content is injected into every downstream session's context — keep it lean and stable. Editing shifts downstream behaviour between versions, so batch edits decisively and land prompt-engineering changes together in one PR; trim for clarity and correctness, not to chase a token count. Full policy: `AGENTS.md` → "Maintenance Rule — Keep Injected Context Lean & Stable".

### STYLE-GUIDE Changes

This file is the canonical source. When updating format rules:

1. Update STYLE-GUIDE.md **first**.
2. Identify affected files: `grep -rn "<changed-pattern>" .github/`
3. Update all affected files to comply with the new rules in the **same PR**.
4. Update `validate-style-guide.sh` if the change introduces a new machine-checkable rule.
5. Never change the STYLE-GUIDE without propagating — a rule that only exists here and not in the files is worse than no rule.
