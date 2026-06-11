# Copilot Configuration Style Guide

Canonical format for every file type under `.github/`. All files MUST follow these skeletons. Format changes require updating this guide first.

## Five Categories

| Category | Role | Responsibility |
|---|---|---|
| **Agent** | Router | Who I am, which workflows I activate, who I hand off to |
| **Skill** | Workflow | Step-by-step process — references Rules and Templates rather than restating them (review/audit checklists may *name* conventions as check items only) |
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
description: '<One-sentence summary — what rules this file covers and for what context.>'
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

1. **Frontmatter**: `description` + `applyTo` — both required, no other fields. `applyTo` must be a non-empty glob pattern (e.g., `**/*.java`). An invalid glob silently prevents the instruction from loading.
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

For manual-only skills, replace the first line:

```
⚠️ MANUAL ONLY — invoke ONLY via /<skill-name>. NEVER auto-trigger.
Use when <trigger scenario>.
```

### Trigger Keyword Design

Guidelines for the `Triggers on:` section in skill descriptions and the corresponding agent Skill Activation table.

- Include both **English AND Chinese** triggers (bilingual user base per `copilot-instructions.md`).
- **4–8 trigger phrases** per skill. Too few = missed intent, too many = false activation.
- Use **verb phrases**, not bare nouns: `"review SQL"` not `"SQL"`.
- Include common **variations and synonyms**: `"怎麼做"` and `"幫我想方案"` for the same skill.
- **No overlap with sibling skills** on the same agent. If a phrase could activate 2 skills, the agent's Skill Activation section must specify a default (e.g., "Default to `implement` if ambiguous").
- Overlap between skills on **different agents** is acceptable — the user's `@agent-name` choice disambiguates.
- **Before adding or changing triggers**, grep sibling skills on the same agent to confirm no overlap: `grep -i "<new-trigger>" .github/skills/*/SKILL.md`.

### Body Skeleton

```markdown
# <Skill Name> — Workflow

<What this skill does (1–2 sentences). Cross-reference to instruction files that define rules.> For code-touching skills, follow with the named canonical instruction file(s) the skill maps to (rule 4) — a bullet list of `instructions/...` references the agent opens on demand. Non-code-touching skills omit this block.

- `instructions/<name>.instructions.md` — <what this file covers>
- `instructions/<name>.instructions.md` — <what this file covers>

## Phase 1 — <Verb Phrase>

<Phase content — instructions, bash commands, tables, etc.>

## Phase N — <Verb Phrase>

<Phase content>

## Rules

- Rule items specific to this skill's workflow

## Handoffs

- → `<skill>` skill — <when to hand off downstream>
- ← `<skill>` skill — <when this skill receives handoff from upstream>

## Anti-Patterns

- <Anti-pattern description> → <consequence or fix>

## Output Template

<CONDITIONAL — only for skills emitting a fixed-shape structured artifact (plan, tasks, code-review, sql-review, schema-migration-review). The deterministic markdown skeleton the skill produces.>
```

### Rules

Each rule is marked **REQUIRED**, **CONDITIONAL**, or **OPTIONAL**.

1. **Frontmatter** (**REQUIRED**): `name` + `description` — both required. The only optional field is `disable-model-invocation: true`, for manual-only skills that must never auto-trigger (e.g., `git-commit`). No `tools` in skill frontmatter (tools belong on agents).
2. **H1** (**REQUIRED**): always `<Skill Name> — Workflow`. No variation (`Executable Workflow`, `Overview`, etc.). **Exception**: `refactor` and `git-commit` are reference+process hybrids where Phase N format would damage readability — they keep their organic structure but must still use `— Workflow` in the H1.
3. **Opening paragraph** (**REQUIRED**): what + cross-references. Name the specific instruction file(s) the skill relates to (e.g., `sql-review` → `instructions/sql.instructions.md`). The instruction-reference block (rule 4) carries the full per-skill set — do not use the `instructions/*.instructions.md` glob to stand in for it.
4. **Instruction reference block** (**CONDITIONAL** — code-touching skills only): required for skills that modify or review code (`implement`, `refactor`, `code-review`, `sql-review`, `schema-migration-review`, `security-audit`, `debug`, `performance`). It names the canonical instruction file(s) the skill maps to as a bullet list of `instructions/<name>.instructions.md` references — name specific files, not the `*` glob, so an agent with file access can open them directly. Each skill lists only the instruction files relevant to its domain (broad skills like `implement` name all; narrow skills like `sql-review` name just theirs). The hard-boundary rules previously duplicated in an inline condensed floor now live in the code-touching agent bodies under `## Coding Standards`.
5. **Phase sections** (**REQUIRED** unless excepted): `## Phase N — <Verb Phrase>`. Verb phrase uses imperative mood (e.g., "Understand Before Writing", "Classify Findings", "Map the Attack Surface"). Numbered sequentially from 1. **Exception**: skills that are inherently reference guides with embedded process (`refactor`, `git-commit`) may use topic-based H2 sections instead.
6. **Rules section** (**OPTIONAL**): include when the skill has rules specific to its own workflow that aren't covered by instruction files. Not a repeat of instruction-level rules. Omit rather than add an empty section.
7. **Handoffs section** (**CONDITIONAL** — required if the skill hands off to or receives from other skills/agents): use `→` for downstream (this skill hands off to) and `←` for upstream (this skill receives from). Reference by skill name in backticks and agent name with `@` prefix.
8. **Anti-Patterns section** (**OPTIONAL**): include when the skill has common misuse patterns. Format as a bullet list with `→` separator, or as a paragraph if context-heavy.
9. **Output Template section** (**CONDITIONAL**): required for skills that produce structured artifacts with a fixed shape — currently `plan`, `tasks`, `code-review`, `sql-review`, `schema-migration-review`. Skills whose output is code, free-form prose, or context-dependent (`implement`, `refactor`, `debug`, `performance`, `security-audit`, `test-design`, `clarify-task`, `git-commit`) do not need this section — their workflow phases, self-verify checklists, or finding-format conventions are sufficient. When adding a new skill, decide by output shape: deterministic markdown skeleton → include the section; per-task variable output → omit.
10. **Subfiles** (**OPTIONAL**): skills may include supporting files (examples, reference data) in subdirectories under the skill folder (e.g., `skills/refactor/examples/`). See the Skill Subfiles section below.

### Skill Subfiles (`skills/<name>/<subdir>/*.md`)

Supporting files referenced by a skill's body (e.g., before/after code examples, reference tables). These are NOT standalone skills — they are supplementary material loaded on demand.

1. **No frontmatter** — subfiles are not auto-triggered or indexed.
2. **H1**: `<Operation> — <Context> Examples`.
3. **Consistent structure across sibling files** — all files in the same subdirectory must follow the same skeleton.
4. **Referenced from parent skill** — the parent `SKILL.md` must reference subfiles by relative path (e.g., `examples/extract-method.md`).

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

1. **Filename pattern** (**REQUIRED**): `<verb>-<object>.prompt.md`. Verb first, lowercase, hyphen-separated. Examples: `check-tx`, `explain-this`, `generate-migration-sql`. Reject noun-first or noun-only names.
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
TOOL_NAME=$(jq -r '.toolName // .tool_name // ""' <<<"$INPUT") \
  || deny "unparseable input (fail-closed)"

# Filter by tool type — fail-closed: fast-path allow known read-only tools,
# all other (incl. unknown) tools fall through to deny-pattern inspection
case "$TOOL_NAME" in
  read_file|list_dir|search|grep|read) exit 0 ;;
  *) ;;
esac

# camelCase surfaces (Copilot CLI, cloud agent) send toolArgs — an object
# or a JSON-encoded string; the VS Code PascalCase payload sends tool_input.
CMD=$(jq -r '(.toolArgs // .tool_input // "")
  | if type == "string" then (fromjson? // .) else . end
  | if type == "object" then (.command // "") else . end
  | tostring' <<<"$INPUT") \
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
6. **Timeout**: `timeout` ≤ 10 (the field name `default.json` uses). Hooks must be fast — they run on every tool call.
7. **No side effects**: hooks inspect input and allow/deny. They must not modify files, write to the workspace, or produce user-visible output (except the deny-decision JSON on stdout and the log line on stderr).
8. **Pattern matching**: use `grep -qiE` (case-insensitive extended regex) for deny patterns. False positives are worse than false negatives — err on the side of allowing.

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
- Agent `handoffs[].agent` values reference existing agent names
- Agent declaring `agents:` in frontmatter includes `'agent'` in its `tools` list (subagent delegation requires the `agent` tool)
- Instruction Anti-Patterns tables use 3-column format (`Pattern | Problem | Fix`)
- Code-touching skills name at least one specific `instructions/<name>.instructions.md` file (not only the `*` glob)
- Code-touching agents (`implementer`, `reviewer`, `debugger`) embed a `## Coding Standards` section, and its hard-boundary bullets (lines starting with `- `) are byte-identical across all three agents (only the per-agent intro sentence may differ); those bullets must be top-level `- ` items — indented sub-bullets or numbered lines, which would escape the byte-identity comparison, are rejected
- All canonical cross-references (`` `instructions/...` ``, `` `skills/...` ``, `` `agents/...` ``) resolve to existing files. Inbound prompt mentions (a skill or agent naming a prompt, e.g. the `find-impact` prompt) are also checked to resolve to a real `prompts/<name>.prompt.md`.

### Tier 2: Human-review (PR review checklist)

These require manual verification. Reviewers should check:

- [ ] H1 follows category naming convention
- [ ] Agent `## Coding Standards` floor covers the version-lock essentials (Java 8 / Spring 3.2 / Hibernate 4.2 / SQL / security) and its content still matches the canonical `instructions/` source of truth (the validator cross-checks byte-equality between agents, but never against `instructions/`)
- [ ] Phase sections use imperative verb phrases
- [ ] No duplicated content across categories — two sanctioned exceptions only: (1) the agent-body `## Coding Standards` embed, and (2) the review/audit verification checklists in `code-review` / `security-audit`, which may *name* conventions as check items but add no detail (see AGENTS.md "Two narrow duplications")
- [ ] Handoff sections are bidirectional (if A → B, then B ← A)
- [ ] Agent Skill Activation table matches the skills that reference that agent
- [ ] Dependency direction rules are respected (see **Dependency Direction** section)
- [ ] Inline skill/agent mentions (`` `@agent` ``, `` `skill-name` ``) reference real entities
- [ ] New/modified trigger keywords do not overlap with sibling skills on the same agent
- [ ] Skills producing structured artifacts have `## Output Template` section (plan, tasks, code-review, sql-review, schema-migration-review)

---

## File Lifecycle

### Renaming or Moving Files

1. Scan for inbound references: `grep -rn "<old-filename>" .github/`
2. Update all references + README tables in the same PR.
3. Run validator: `bash .github/scripts/validate-style-guide.sh`

Broken paths silently degrade Copilot output — they do not error.

### Editing Existing Files (Cache-Friendly)

Under Copilot usage-based billing, `instructions/` / `agents/` / `skills/` content sits in the **prompt-cache prefix**. Caching is prefix-based: editing one line invalidates that file's cached segment and everything after it, forcing a cache-write rebuild next session.

1. Batch edits — change a file once, decisively. Do **not** micro-tune for token count.
2. Edit for clarity or correctness, never *purely* to shave tokens (cache already neutralised that cost).
3. Land prompt-engineering changes together in one PR, not as a drip of small commits.

See `AGENTS.md` → "Maintenance Rule — Cache-Friendly Edits" for the rationale.

### STYLE-GUIDE Changes

This file is the canonical source. When updating format rules:

1. Update STYLE-GUIDE.md **first**.
2. Identify affected files: `grep -rn "<changed-pattern>" .github/`
3. Update all affected files to comply with the new rules in the **same PR**.
4. Update `validate-style-guide.sh` if the change introduces a new machine-checkable rule.
5. Never change the STYLE-GUIDE without propagating — a rule that only exists here and not in the files is worse than no rule.
