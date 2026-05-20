# Copilot Configuration Style Guide

Canonical format for every file type under `.github/`. All files MUST follow these skeletons. Format changes require updating this guide first.

## Five Categories

| Category | Role | Responsibility |
|---|---|---|
| **Agent** | Router | Who I am, which workflows I activate, who I hand off to |
| **Skill** | Workflow | Step-by-step process — references Rules and Templates, never rewrites them |
| **Instruction** | Rules | Single source of truth for coding conventions — referenced by workflows |
| **Prompt** | Shortcut | Lightweight single-task shortcuts invoked via `/prompt-name` |
| **Hook** | Lifecycle Guard | Block dangerous commands before agent tool execution |

```text
Hook (Guard) ──lifecycle guard──→ Agent (Router) ──activates──→ Skill (Workflow + Output Template)
                                                                       │
                                                                       └──rules──→ Instruction (Rules)

Prompt (Shortcut) ──manual /prompt-name──→ Standalone execution
```

Each category has ONE job. Content that belongs in another category MUST be delegated, not copied. See **Dependency Direction** and **Delegation Architecture** sections for enforcement rules.

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
   - `Skill Activation` — table of trigger → skill → output (all agents that activate skills must have this)
   - `Subagent Delegation` — delegation instructions
   - `Workflow` — process description (only if not fully covered by skills)
   - `Constraints` — constraints list
   - `Handoff Guidance` — when to hand off to other agents (always last body section)
5. **Lightweight agents** (subagents like `researcher`): may use a minimal structure (`Rules` + `Output Format`) instead of the full skeleton. Frontmatter must still be complete.
6. **Handoff target validation**: every `handoffs[].agent` value must match an existing agent `name` (case-sensitive). A typo silently breaks the VS Code handoff button — there is no runtime error.
7. **Handoff format** (when `handoffs` is present in frontmatter):
   - `label`: short imperative phrase (≤ 10 characters). Chinese preferred for consistency with `copilot-instructions.md` response language; English acceptable for widely recognized terms (e.g., `Code Review`).
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
- Include common **variations and synonyms**: `"寫 SDD"` and `"寫規格"` for the same skill.
- **No overlap with sibling skills** on the same agent. If a phrase could activate 2 skills, the agent's Skill Activation section must specify a default (e.g., "Default to `implement` if ambiguous").
- Overlap between skills on **different agents** is acceptable — the user's `@agent-name` choice disambiguates.
- **Before adding or changing triggers**, grep sibling skills on the same agent to confirm no overlap: `grep -i "<new-trigger>" .github/skills/*/SKILL.md`.

### Body Skeleton

```markdown
# <Skill Name> — Workflow

<What this skill does (1–2 sentences). Cross-reference to instruction files that define rules.> Key rules (fallback for agent chat context when instructions are not auto-loaded):

- **<Category>**: <inline rule summary>
- **<Category>**: <inline rule summary>

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
```

### Rules

Each rule is marked **REQUIRED**, **CONDITIONAL**, or **OPTIONAL**.

1. **Frontmatter** (**REQUIRED**): `name` + `description` — both required, no other fields. No `tools` in skill frontmatter (tools belong on agents).
2. **H1** (**REQUIRED**): always `<Skill Name> — Workflow`. No variation (`Executable Workflow`, `Overview`, etc.). **Exception**: `refactor` and `git-commit` are reference+process hybrids where Phase N format would damage readability — they keep their organic structure but must still use `— Workflow` in the H1.
3. **Opening paragraph** (**REQUIRED**): what + cross-references. Name the specific instruction file(s) the skill relates to (e.g., `sql-review` → `instructions/sql.instructions.md`). The fallback block (rule 4) carries the full per-skill set — do not use the `instructions/*.instructions.md` glob to stand in for it.
4. **Fallback rules block** (**CONDITIONAL** — code-touching skills only): required for skills that modify or review code (`implement`, `refactor`, `code-review`, `sql-review`, `schema-migration-review`, `pom-review`, `security-audit`, `debug`, `performance`). Two layers: (a) a **named list of the canonical instruction files** the skill maps to — name specific files, not the `*` glob, so an agent with file access can open them directly; and (b) an inline **condensed floor** of the critical non-negotiable rules for when files can't be opened, written as a bullet list with bold category labels (≥3) and introduced by `Key rules (fallback for agent chat):`. Each skill lists only the instruction files relevant to its domain (broad skills like `implement` name all; narrow skills like `pom-review` name just theirs).
5. **Phase sections** (**REQUIRED** unless excepted): `## Phase N — <Verb Phrase>`. Verb phrase uses imperative mood (e.g., "Understand Before Writing", "Classify Findings", "Map the Attack Surface"). Numbered sequentially from 1. **Exception**: skills that are inherently reference guides with embedded process (`refactor`, `git-commit`) may use topic-based H2 sections instead.
6. **Rules section** (**OPTIONAL**): include when the skill has rules specific to its own workflow that aren't covered by instruction files. Not a repeat of instruction-level rules. Omit rather than add an empty section.
7. **Handoffs section** (**CONDITIONAL** — required if the skill hands off to or receives from other skills/agents): use `→` for downstream (this skill hands off to) and `←` for upstream (this skill receives from). Reference by skill name in backticks and agent name with `@` prefix.
8. **Anti-Patterns section** (**OPTIONAL**): include when the skill has common misuse patterns. Format as a bullet list with `→` separator, or as a paragraph if context-heavy.
9. **Output Template section** (**CONDITIONAL**): required for skills that produce structured artifacts with a fixed shape — currently `plan`, `sdd`, `tasks`, `code-review`, `sql-review`. Skills whose output is code, free-form prose, or context-dependent (`implement`, `refactor`, `debug`, `performance`, `security-audit`, `test-design`, `sdd-review`, `clarify-task`, `git-commit`) do not need this section — their workflow phases, self-verify checklists, or finding-format conventions are sufficient. When adding a new skill, decide by output shape: deterministic markdown skeleton → include the section; per-task variable output → omit.
10. **Subfiles** (**OPTIONAL**): skills may include supporting files (examples, reference data) in subdirectories under the skill folder (e.g., `skills/refactor/examples/`). See the Skill Subfiles section below.

### Skill Subfiles (`skills/<name>/<subdir>/*.md`)

Supporting files referenced by a skill's body (e.g., before/after code examples, reference tables). These are NOT standalone skills — they are supplementary material loaded on demand.

1. **No frontmatter** — subfiles are not auto-triggered or indexed.
2. **H1**: `<Operation> — <Context> Examples`.
3. **Consistent structure across sibling files** — all files in the same subdirectory must follow the same skeleton.
4. **Referenced from parent skill** — the parent `SKILL.md` must reference subfiles by relative path (e.g., `examples/extract-method.md`).

---

## Prompts (`prompts/*.prompt.md`)

Standalone single-task shortcuts the user invokes via `/<prompt-name>`. NOT referenced by skills — prompts are independent of the agent/skill graph.

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
        "timeoutSec": 5
      }
    ]
  }
}
```

### Script Skeleton (`hooks/scripts/*.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // ""')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.toolInput // "" | if type == "object" then tostring else . end')

# Filter by tool type — exit 0 early for irrelevant tools
case "$TOOL_NAME" in
  shell_command|terminal|bash|run_command) ;;
  *) exit 0 ;;
esac

# Deny patterns (case-insensitive)
DENY_PATTERNS="<pipe-separated regex patterns>"

if echo "$TOOL_INPUT" | grep -qiE "$DENY_PATTERNS" 2>/dev/null; then
  echo "DENY: <reason>" >&2
  exit 2
fi

exit 0
```

### Rules

1. **Shebang**: `#!/usr/bin/env bash` on line 1.
2. **Error handling**: `set -euo pipefail` on line 2.
3. **Exit codes**: `0` = allow, `2` = deny. Exit `1` indicates a script error (not a policy decision) — Copilot treats it differently from `2`.
4. **Input format**: JSON on stdin with `toolName` (string) and `toolInput` (string or object). Parse with `jq`.
5. **Tool filtering**: always check `TOOL_NAME` first and `exit 0` for irrelevant tool types. Never inspect non-shell tools.
6. **Timeout**: `timeoutSec` ≤ 10. Hooks must be fast — they run on every tool call.
7. **No side effects**: hooks inspect input and allow/deny. They must not modify files, write to the workspace, or produce user-visible output (except the deny message on stderr).
8. **Pattern matching**: use `grep -qiE` (case-insensitive extended regex) for deny patterns. False positives are worse than false negatives — err on the side of allowing.

---

## Cross-Reference Format (all categories)

| Reference type | Format | Example | Validated? |
|---|---|---|---|
| Instruction file | `` `instructions/<name>.instructions.md` `` | `` `instructions/sql.instructions.md` `` | ✅ CI |
| Instruction glob (all) | `` `instructions/*.instructions.md` `` | Used in skill fallback intro when depending on all instructions | ❌ |
| Skill file | `` `skills/<name>/SKILL.md` `` | `` `skills/plan/SKILL.md` `` | ✅ CI |
| Agent file | `` `agents/<name>.agent.md` `` | `` `agents/planner.agent.md` `` | ✅ CI |
| Agent mention | `` `@agent-name` `` | `` `@implementer` `` | ❌ |
| Skill mention (inline) | `` `skill-name` `` or `` `skill-name` skill `` | `` `plan` skill `` | ❌ |
| Global instructions | `` `copilot-instructions.md` `` | `` `copilot-instructions.md` `` | ❌ |

All paths are relative from `.github/`. Never use bare names without context (e.g., `` `sql-rules` `` alone) — always include enough path to be unambiguous.

The **Validated?** column indicates whether `validate-style-guide.sh` automatically checks that the referenced file exists. References marked ❌ require manual verification during PR review.

---

## Validation Tiers

What is machine-checked vs. what requires human review.

### Tier 1: Machine-checked (`validate-style-guide.sh` + CI)

These are enforced automatically on every PR that touches `.github/**/*.md`.

- Instruction frontmatter has `description` + `applyTo`
- Instruction `applyTo` value is non-empty
- Skill frontmatter has `name` + `description`
- Skill `name` matches its parent directory name
- Skill `description` ≤ 1024 characters
- Skill `description` contains required markers (`Use when`, `Triggers on:`, `Do NOT use`) — exempted for `disable-model-invocation: true` skills
- No `tools` field in skill frontmatter
- Prompt frontmatter has `agent` + `description`
- Agent frontmatter has `name`, `description`, `model`, `tools`
- Agent `handoffs[].agent` values reference existing agent names
- Instruction Anti-Patterns tables use 3-column format (`Pattern | Problem | Fix`)
- All canonical cross-references (`` `instructions/...` ``, `` `skills/...` ``, `` `prompts/...` ``, `` `agents/...` ``) resolve to existing files

### Tier 2: Human-review (PR review checklist)

These require manual verification. Reviewers should check:

- [ ] H1 follows category naming convention
- [ ] Fallback rules block present on code-touching skills (`implement`, `refactor`, `code-review`, `sql-review`, `security-audit`, `debug`, `performance`)
- [ ] Phase sections use imperative verb phrases
- [ ] No duplicated content across categories (sanctioned fallback rules excepted)
- [ ] Handoff sections are bidirectional (if A → B, then B ← A)
- [ ] Agent Skill Activation table matches the skills that reference that agent
- [ ] Dependency direction rules are respected (see **Dependency Direction** section)
- [ ] Inline skill/agent mentions (`` `@agent` ``, `` `skill-name` ``) reference real entities
- [ ] New/modified trigger keywords do not overlap with sibling skills on the same agent
- [ ] Skills producing structured artifacts have `## Output Template` section (plan, sdd, tasks, code-review, sql-review)

---

## File Lifecycle

### Renaming or Moving Files

1. Scan for inbound references: `grep -rn "<old-filename>" .github/`
2. Update all references + README tables in the same PR.
3. Run validator: `bash .github/scripts/validate-style-guide.sh`

Broken paths silently degrade Copilot output — they do not error.

### STYLE-GUIDE Changes

This file is the canonical source. When updating format rules:

1. Update STYLE-GUIDE.md **first**.
2. Identify affected files: `grep -rn "<changed-pattern>" .github/`
3. Update all affected files to comply with the new rules in the **same PR**.
4. Update `validate-style-guide.sh` if the change introduces a new machine-checkable rule.
5. Never change the STYLE-GUIDE without propagating — a rule that only exists here and not in the files is worse than no rule.
