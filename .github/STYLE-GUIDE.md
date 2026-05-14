# Copilot Configuration Style Guide

Canonical format for every file type under `.github/`. All files MUST follow these skeletons. Format changes require updating this guide first.

## Four Categories

| Category | Role | Responsibility |
|---|---|---|
| **Agent** | 角色 | Who I am, which workflows I activate, who I hand off to |
| **Skill** | 工作流程 | Step-by-step process — references Rules and Templates, never rewrites them |
| **Instruction** | 規則 | Single source of truth for coding conventions — referenced by workflows |
| **Prompt** | 模板 | Output format scaffolds — referenced by workflows |

```text
Agent (角色) ──activates──→ Skill (工作流程) ──output format──→ Prompt (模板)
                                  │
                                  └──rules──→ Instruction (規則)
```

Each category has ONE job. Content that belongs in another category MUST be delegated, not copied. See **Delegation Architecture** section for enforcement rules.

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

<Scope statement (1–2 sentences). Use "Hard rules for..." when the file defines non-negotiable conventions; otherwise, start with a direct statement of what this file covers.> Cross-reference related files using relative paths from `.github/`: e.g., `instructions/sql-rules.instructions.md`, `prompts/code-review-checklist.prompt.md`.

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

1. **Frontmatter**: `description` + `applyTo` — both required, no other fields.
2. **H1**: descriptive title. No filename suffix, no category prefix.
3. **Opening paragraph**: scope statement + cross-references to related instruction/prompt files (if any). Use full relative paths from `.github/` (e.g., `instructions/security-and-owasp.instructions.md`), not bare names.
4. **Body sections**: H2 for topic grouping. Use bullet lists for rules, tables for quick-reference lookups. **Exception**: files with ≤3 lines of content (e.g., `no-heredoc`) may omit H2 sections.
5. **Anti-Patterns table**: always 3-column (`Pattern | Problem | Fix`). If the file has anti-patterns, use this exact header. Column 2 (`Problem`) must explain *why* it's wrong, not just restate the pattern.
6. **Checklist section**: optional. Use only when the instruction benefits from a verification self-check (e.g., markdown formatting, commenting guidelines). Use `- [ ]` checkbox format.
7. **Cross-references**: use backtick-wrapped relative paths from `.github/` — e.g., `` `instructions/sql-rules.instructions.md` ``. Never use bare names like `` `sql-rules` `` or absolute paths.
8. **Known exceptions**: `global-copilot.instructions.md` is intentionally minimal (duplicates `copilot-instructions.md` for user-scope loading) — opening paragraph and H2 sections are not required.

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

### Body Skeleton

```markdown
# <Skill Name> — Workflow

<What this skill does (1–2 sentences). Cross-reference to instruction/prompt files that define rules or output format.> Key rules (fallback for agent chat context when instructions are not auto-loaded):

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
3. **Opening paragraph** (**REQUIRED**): what + cross-references. Must reference the paired prompt file (if any) and the relevant instruction files.
4. **Fallback rules block** (**CONDITIONAL** — code-touching skills only): required for skills that modify or review code (`implement`, `refactor`, `code-review`, `sql-review`, `security-audit`, `debug`, `performance`). These inline the critical non-negotiable rules so they apply even when instruction files are not auto-loaded in agent chat. Format as a bullet list with bold category labels.
5. **Phase sections** (**REQUIRED** unless excepted): `## Phase N — <Verb Phrase>`. Verb phrase uses imperative mood (e.g., "Understand Before Writing", "Classify Findings", "Map the Attack Surface"). Numbered sequentially from 1. **Exception**: skills that are inherently reference guides with embedded process (`refactor`, `git-commit`) may use topic-based H2 sections instead.
6. **Rules section** (**OPTIONAL**): include when the skill has rules specific to its own workflow that aren't covered by instruction files. Not a repeat of instruction-level rules. Omit rather than add an empty section.
7. **Handoffs section** (**CONDITIONAL** — required if the skill hands off to or receives from other skills/agents): use `→` for downstream (this skill hands off to) and `←` for upstream (this skill receives from). Reference by skill name in backticks and agent name with `@` prefix.
8. **Anti-Patterns section** (**OPTIONAL**): include when the skill has common misuse patterns. Format as a bullet list with `→` separator, or as a paragraph if context-heavy.
9. **Internal templates** (**CONDITIONAL**): skills that produce artifacts (spike, constitution) MAY embed the template directly. Skills that share a template with other skills MUST reference a prompt file instead (e.g., `prompts/plan-template.prompt.md`).
10. **Subfiles** (**OPTIONAL**): skills may include supporting files (examples, reference data) in subdirectories under the skill folder (e.g., `skills/refactor/examples/`). See the Skill Subfiles section below.

### Skill Subfiles (`skills/<name>/<subdir>/*.md`)

Supporting files referenced by a skill's body (e.g., before/after code examples, reference tables). These are NOT standalone skills — they are supplementary material loaded on demand.

```markdown
# <Operation or Topic> — <Context> Examples

<One-sentence scope statement.>

## When to Trigger

<Criteria for applying this operation — thresholds, heuristics, or conditions.>

## Rules

- Rule items specific to this operation

---

## Example N — <Short Title>

### Before

\`\`\`java
<original code>
\`\`\`

### After

\`\`\`java
<refactored code>
\`\`\`

**What changed**: <one-sentence explanation of the transformation and why it improves the code.>
```

Rules for subfiles:

1. **No frontmatter** — subfiles are not auto-triggered or indexed. No `name`, `description`, or `applyTo`.
2. **H1**: `<Operation> — <Context> Examples` (e.g., `Extract Method — Java Examples`).
3. **Consistent structure across sibling files** — all examples in the same `examples/` directory must follow the same skeleton (When to Trigger → Rules → Example sections).
4. **Each example**: `## Example N — <Short Title>` with `### Before`, `### After`, and a bold `**What changed**` summary.
5. **Horizontal rules** (`---`) between examples for visual separation.
6. **Referenced from parent skill** — the parent `SKILL.md` must reference subfiles by relative path (e.g., `examples/extract-method.md`). Relative paths within the same skill directory are acceptable.

---

## Prompts (`prompts/*.prompt.md`)

Three subtypes, each with its own skeleton. Subtype is determined by the filename suffix.

### Common Frontmatter

```yaml
---
agent: 'agent'
description: '<Description. Pairs with skills/<skill>/SKILL.md (what the paired skill provides vs what this prompt provides).>'
---
```

Avoid `tools` field in prompt frontmatter — tools generally belong on agents. Exception: `-output` prompts that function as active review workflows may declare tools if they need them at invocation time.

### Subtype 1: Template (`*-template.prompt.md`)

One-shot scaffold for artifact creation.

```markdown
# <Name> Template

<One-sentence description: "One-shot scaffold for <artifact>."> Workflow (phases, validation, prerequisites) lives in `skills/<skill>/SKILL.md`. This prompt only defines the OUTPUT FORMAT.

## Usage

Invoke via `/<prompt-name>`. <Preconditions, filename convention, placeholder rules.>

## Template

\`\`\`md
<The scaffold with ${input:field:default} placeholders>
\`\`\`

## Validation Checklist

- [ ] Every `${input:...}` placeholder replaced
- [ ] <Domain-specific validation items>
```

### Subtype 2: Checklist (`*-checklist.prompt.md`)

Verification checklist with categorized items.

```markdown
# <Name> Standards

<What to check + cross-reference to paired skill for workflow/verdict.>

## Severity Mapping

| Severity | Includes |
|---|---|
| CRITICAL | ... |
| WARNING | ... |
| SUGGESTION | ... |

## <Category>

- Check items

## Comment Format

\`\`\`
[SEVERITY] Category — Title
  File: path/to/File.java#method:line
  Problem: <what + why>
  Fix: <recommendation>
\`\`\`
```

### Subtype 3: Output (`*-output.prompt.md`)

Output format / cheat-sheet reference cited by its paired skill.

```markdown
# <Name>

<What this prompt defines + cross-reference to paired skill for workflow.>

## <Reference Table / Cheat Sheet>

| Column | Column | Column |
|---|---|---|
| ... | ... | ... |

## Output Format

<Format specification with code block example.>
```

### Rules

1. **Frontmatter**: `agent` + `description` — both required. No `tools` field.
2. **Subtype naming**: `-template` for scaffolds, `-checklist` for verification lists, `-output` for format references. Suffix determines which skeleton to follow.
3. **Placeholder syntax**: `${input:field:default}` for user-prompted values in `-template` prompts. VS Code built-in variables (`${selection}`, `${file}`, etc.) are valid in non-template prompts and descriptions — do not replace them with `${input:...}`.
4. **Validation Checklist**: required for `-template` prompts. First item is always "Every `${input:...}` placeholder replaced".
5. **Cross-references**: every prompt MUST reference its paired skill in the opening paragraph using `` `skills/<skill>/SKILL.md` ``.
6. **Separation of concerns**: templates define OUTPUT FORMAT only. Workflow, validation rules, and prerequisites live in the paired skill.

---

## Delegation Architecture

### Delegation Rules

| From | To | What is delegated | How |
|---|---|---|---|
| Skill | Instruction | Coding rules and conventions | Reference via cross-ref in opening paragraph or fallback rules block. Never duplicate full rule sets — fallback blocks are ONE-LINE summaries per category only. |
| Skill | Prompt | Output format and templates | Reference via cross-ref. Skills that share a template with other skills MUST use a prompt file. Skills with unique templates MAY embed them directly. |
| Skill | Agent / Skill | Execution handoff | `## Handoffs` section with `→` / `←` markers. |
| Agent | Skill | Workflow execution | `## Skill Activation` table maps triggers to skills. Agent body says "follow the skill's workflow" — never rewrites it. |
| Prompt | Skill | Workflow and validation | Opening paragraph references paired skill. Prompt defines OUTPUT FORMAT only — workflow lives in the skill. |
| Instruction | Instruction | Related conventions | Cross-ref in opening paragraph to sibling instruction files. |

### Violations

| Violation | Example | Fix |
|---|---|---|
| **Rule duplication** | Skill contains a full Anti-Patterns table copied from an instruction file | Delete from skill; add a fallback one-liner + cross-ref to the instruction |
| **Template duplication** | Two skills embed the same output scaffold | Extract to a prompt file; both skills reference it |
| **Workflow duplication** | Agent body describes step-by-step process that a skill already defines | Delete from agent; add "follow the `<skill>` skill workflow" |
| **Missing delegation** | Skill produces a structured artifact but has no paired prompt or embedded template | Create a prompt file OR embed the template (if not shared) |
| **Orphaned resource** | Prompt file exists but no skill references it; skill exists but no agent activates it | Either add the reference or delete the orphan |

### Bidirectional References

When resource A delegates to resource B, both sides SHOULD reference each other:

- Skill references prompt → prompt references skill back (in opening paragraph)
- Skill references instruction → instruction MAY reference skill back (optional — instructions are lower-level)
- Agent activates skill → skill's Handoffs MAY reference agent back (via `@agent`)

Bidirectional references are RECOMMENDED, not required. The critical direction is **downstream** (the delegator must reference the delegate). Upstream back-references are nice-to-have for navigation.

---

## Cross-Reference Format (all categories)

| Reference type | Format | Example |
|---|---|---|
| Instruction file | `` `instructions/<name>.instructions.md` `` | `` `instructions/sql-rules.instructions.md` `` |
| Skill file | `` `skills/<name>/SKILL.md` `` | `` `skills/plan/SKILL.md` `` |
| Prompt file | `` `prompts/<name>.prompt.md` `` | `` `prompts/plan-template.prompt.md` `` |
| Agent file | `` `agents/<name>.agent.md` `` | `` `agents/planner.agent.md` `` |
| Agent mention | `` `@agent-name` `` | `` `@implementer` `` |
| Skill mention (inline) | `` `skill-name` `` or `` `skill-name` skill `` | `` `plan` skill `` |
| Global instructions | `` `copilot-instructions.md` `` | `` `copilot-instructions.md` `` |

All paths are relative from `.github/`. Never use bare names without context (e.g., `` `sql-rules` `` alone) — always include enough path to be unambiguous.
