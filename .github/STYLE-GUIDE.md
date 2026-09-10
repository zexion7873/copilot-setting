# Copilot Configuration Style Guide

Canonical format for every file type under `.github/`. All files MUST follow the frontmatter and rules for their category; an existing sibling file is the worked example for body structure. Format changes require updating this guide first.

The category roles and activation pipeline (Hooks → Agents → Skills → Instructions; Prompts standalone) are defined once in `AGENTS.md` → **Architecture** — this guide does not repeat the diagram.
Each category has ONE job; content that belongs in another category MUST be referenced, not copied.

---

## Instructions (`instructions/*.instructions.md`)

### Frontmatter (required fields)

```yaml
---
description: '<Selectability hint — domain, then concrete triggers, then where to defer. One dense line.>'
applyTo: '<glob pattern>'
---
```

### Rules

1. **Frontmatter**: `description` + `applyTo` — both required, no other fields. `applyTo` must be a non-empty glob (an invalid glob silently prevents the instruction from loading). The `description` is the model's **selectability hint** for on-demand loading — VS Code passes every instruction's description into each request. Lead with the domain, then concrete triggers (task contexts, co-occurring symbols, version-lock negatives), then where to defer to a sibling; keep it one dense line.
2. **H1**: descriptive title — no filename suffix, no category prefix.
3. **Body**: opening scope statement + cross-references, then H2 topic sections — bullet lists for rules, tables for quick-reference lookups.
4. **Checklist section**: optional `- [ ]` self-check — include only when the instruction benefits from one.
5. **Cross-references**: backtick-wrapped relative paths from `.github/` (e.g., `` `instructions/sql.instructions.md` ``) — never bare names or absolute paths.

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

### Rules

1. **Frontmatter**: `name`, `description`, `model`, `tools` — all required. `agents` and `handoffs` — include only when applicable.
2. **H1**: `<Name> — <Role Subtitle>`; the subtitle names the specialist domain.
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
7. **Handoff format** (when `handoffs` is present): `label` — short imperative phrase ≤ 12 characters (CJK labels typically 4–5 glyphs), Chinese preferred, English acceptable for widely recognized terms; `prompt` — one sentence in Chinese, starting with `請`; `send: false` is the default (the user confirms before handoff) — use `send: true` only for fully automated handoffs (none currently exist).

---

## Skills (`skills/*/SKILL.md`)

### Frontmatter (required fields)

```yaml
---
name: <skill-name>
description: '<Three-part description — see below.>'
disable-model-invocation: true    # optional — manual-only skills (invoked solely via /<skill-name>)
---
```

### Description Format (recommended convention)

No longer machine-checked — kept as the house convention because the description is the only routing signal the model sees when deciding whether to load a skill:

```
Use when <trigger scenario>. Triggers on: <en-keywords>, <zh-keywords>. <One-sentence summary of what the skill produces.> Do NOT use for <exclusion> (prefer <alternative-skill>).
```

For manual-only skills (`disable-model-invocation: true`) the entire description is `⚠️ MANUAL ONLY — invoke ONLY via /<skill-name>. NEVER auto-trigger.` plus the trigger scenario — keywords and exclusions are meaningless for a skill that never auto-triggers.

### Trigger Keyword Design

- Bilingual **verb phrases** (English + Chinese), not bare nouns: `"review SQL"`, not `"SQL"`.
- **4–10 phrases per intent domain** — every extra phrase widens the false-activation surface; the 1024-char description cap is a platform limit, not a design budget.
- **No overlap with sibling skills on the same agent** — grep before adding: `grep -i "<new-trigger>" .github/skills/*/SKILL.md`. Cross-agent overlap is fine; the user's `@agent` choice disambiguates.
- If a phrase could plausibly activate two sibling skills, the agent's Skill Activation section must name a default (e.g., "Default to `implement` if ambiguous").

### Rules

Each rule is marked **REQUIRED**, **CONDITIONAL**, or **OPTIONAL**.

1. **Frontmatter** (**REQUIRED**): `name` + `description`. Only optional field: `disable-model-invocation: true` for manual-only skills. No `tools` in skill frontmatter (tools belong on agents).
2. **H1** (**REQUIRED**): always `<Skill Name> — Workflow` — no variation, no exceptions, including the reference+process hybrid (`refactor`).
3. **Opening paragraph** (**REQUIRED**): what the skill does + the specific instruction file(s) it relates to. The Phase 0 block (rule 4) carries the full per-skill set — never the `instructions/*.instructions.md` glob.
4. **Instruction reference block** (**CONDITIONAL** — code-touching skills only: `implement`, `refactor`, `code-review`, `sql-review`, `security-audit`, `debug`): `## Phase 0 — Load canonical rules` names the canonical file(s) as specific `instructions/<name>.instructions.md` bullets (never the `*` glob) and closes with the read-back receipt — NAME each file opened, QUOTE its most load-bearing applicable rule. Broad skills name all relevant files; narrow skills just theirs. Human-reviewed — no longer machine-checked.
5. **Phase sections** (**REQUIRED** unless excepted): `## Phase N — <Verb Phrase>`, imperative mood, numbered from 1; `## Phase 0 — Load canonical rules` (rule 4) is the only sanctioned Phase 0. **Exception**: the reference-style skill (`refactor`) may use topic-based H2 sections, with the pre-load gate as a bare leading `## Load canonical rules`.
6. **Rules section** (**OPTIONAL**): workflow-specific rules only — never a repeat of instruction-level rules. Omit rather than add an empty section.
7. **Handoffs section** (**CONDITIONAL** — required when the skill hands off downstream): downstream `→` targets only — never upstream `←` lines (they duplicate the source's `→` and drift; reverse lookup: `grep -rn "→ \`<name>\`" .github/`). Skills by backticked name, agents with `@` prefix. Always the last body section when present.
8. **Anti-Patterns section** (**OPTIONAL**): bullet list with `→` separator, or a paragraph if context-heavy.
9. **Output Template section** (**CONDITIONAL**): required for fixed-shape structured artifacts — currently `plan`, `tasks`, `code-review`, `sql-review`. Decide by output shape: deterministic markdown skeleton → include; code, prose, or per-task variable output → omit.

---

## Prompts (`prompts/*.prompt.md`)

Standalone single-task shortcuts the user invokes via `/<prompt-name>`. A prompt **body** must not reference skills or agents (a prompt is a leaf of the graph), but a skill or agent **may** name a prompt as a suggested shortcut (e.g. the `find-impact` prompt) — that inbound mention is allowed and is validated to resolve.

### Frontmatter (required fields)

Do **not** set `agent:`. Omitting it means the prompt runs under whatever agent is already selected, so `/check-tx` invoked from `@implementer` keeps that agent's `## Coding Standards` floor loaded. Pinning `agent: 'agent'` switches to the built-in agent and discards the floor — the only deterministic channel a prompt has for the version lock.

```yaml
---
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

### Rules

1. **Filename** (**REQUIRED**): `<verb>-<object>.prompt.md` — verb first, lowercase, hyphen-separated (e.g., `check-tx`, `find-impact`). Reject noun-first or noun-only names.
2. **Body** (**REQUIRED**): English (prompts may be injected into any user's context per `copilot-instructions.md`). One imperative sentence followed by a numbered list of aspects/checks — no Markdown headings, no phase structure, under 20 lines. Longer workflows belong in a skill.
3. **No skill references** (**REQUIRED**): prompts must not link to `skills/*/SKILL.md` — if output overlaps a skill, invoke the skill instead.

---

## Hooks (`hooks/`)

Lifecycle guards that intercept agent tool calls before execution. Hooks inspect — they never modify files, write to the workspace, or produce user-visible output (except the deny-decision JSON on stdout and a log line on stderr).

### Configuration (`hooks/default.json`)

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "bash": "bash .github/hooks/scripts/<script-name>.sh",
        "timeout": 30
      }
    ]
  }
}
```

### Script Skeleton

Start any new hook script as a copy of the live, regression-tested `hooks/scripts/block-dangerous-commands.sh` — do not reinvent the stdin parsing, fail-closed gates, or deny plumbing.

### Rules

1. **Deny = decision JSON + exit 0**: print `{"permissionDecision":"deny","permissionDecisionReason":"…"}` to stdout and exit `0` — Copilot parses the decision JSON *only* on exit 0, and the reason lets the agent self-correct. Allow = exit `0` with no decision JSON. **Never exit `2` to deny** — Copilot treats exit 2 as a non-blocking warning and the tool call proceeds. Any other non-zero exit is a script error, which `preToolUse` handles fail-closed (denied, without a readable reason).
2. **Input format**: JSON on stdin. camelCase surfaces (Copilot CLI, cloud agent) send `toolName` and `toolArgs` (object **or JSON-encoded string** — unwrap with `fromjson?`); the VS Code PascalCase payload sends `tool_name` and `tool_input`. Parse with `jq` fallback chains covering both. `toolInput` does not exist in any payload — reading it silently yields an empty string and the hook inspects nothing.
3. **Timeout silently allows**: on expiry the fallback is **allow, not deny** — a timed-out blocking hook is bypassed and a late deny is discarded (github/copilot-cli#2893; hook dispatch is also serialized under parallel tool calls, so queue delay eats the budget). Treat `timeout` as a latency budget, never a safety control: keep hooks fast, keep `timeout` ≤ 30 (the platform default), and do not set it aggressively low on a blocking hook.
4. **Tool filtering & pattern trade-off**: check `TOOL_NAME` first. This repo's hook is **fail-closed**: known read-only tools exit 0 immediately; every other tool — including unknown ones — falls through to deny-pattern inspection. For deny patterns (`grep -qiE`), false positives are worse than false negatives — err on the side of allowing (trade-off recorded in the dangerous-command block-list section of `AGENTS.md`). This governs pattern design only; a grep error during matching (RC ≥ 2) stays fail-closed.

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

---

## Validation Tiers

What is machine-checked vs. what requires human review.

### Tier 1: Machine-checked (`validate-style-guide.sh` + CI)

Enforced automatically on every PR that touches `.github/**/*.md`, the validator script, `.github/hooks/**`, or the workflow file.

- Frontmatter is a terminated `---` block starting at line 1 — an unterminated block is treated as no frontmatter at all
- Instruction frontmatter has `description` + `applyTo`, both non-empty
- Skill frontmatter has `name` + `description`; `name` matches the parent directory name; `description` ≤ 1024 characters; no `tools` field (tools belong on agents)
- Prompt frontmatter has a non-empty `description`
- Agent frontmatter has `name`, `description`, `model`, `tools`
- Agent and prompt `description` (and prompt `agent`, if present) reject YAML block scalars `|`/`>`; skill `description` also rejects multi-line plain/quoted scalars — multi-line values are unparsed and would bypass the 1024-char cap
- Agent `handoffs[].agent` values reference existing agent names (case-sensitive)
- An agent declaring `agents:` includes `'agent'` in its `tools` list (subagent delegation requires the `agent` tool)
- Code-touching agents (`implementer`, `reviewer`, `debugger`) embed `## Coding Standards`, and its hard-boundary bullets (lines starting with `- `) are byte-identical across all three — only the `- ` lines are compared (per-agent intro prose may differ; prose drift is a Tier-2 check), and only top-level `- ` bullets are allowed, since indented lines, `*`/`+` bullets, or numbered items would escape the byte comparison
- Floor↔instruction canary: each floor bullet's load-bearing anchor token appears verbatim in BOTH the `## Coding Standards` floor and the **body** of its mapped `instructions/` file (frontmatter excluded — `description:` trigger keywords would mask a deleted rule). This machine-checks the floor↔source link the byte-identity check cannot (that one compares floor to floor only). The validator holds the anchor→file registry — dropping the rule on either side trips it; rewording an anchor requires updating the registry
- All canonical cross-references (`` `instructions/...` ``, `` `skills/...` ``, `` `agents/...` ``, `` `prompts/...` ``) resolve to existing files; name-style prompt mentions (backticked name + the word "prompt") resolve to a real `prompts/<name>.prompt.md`

### Tier 2: Human-review

**Floor ↔ Instruction map** — each floor bullet is a condensed paraphrase of a canonical rule, so the validator cannot byte-check the full paraphrase against `instructions/`; only the per-bullet **anchor token** is machine-checked (the Tier-1 canary; registry lives in the validator). When you change a floor bullet, its source, or an anchor token, re-check the pair AND update the canary registry:

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
2. Enumerated skill lists in this file: the instruction-reference rule, the Output Template rule, and the review checklist.
3. `AGENTS.md`: Architecture table category counts, the instruction-loading-model skill lists, and the Agent Roster table.
4. `README.md` + `README.zh-TW.md` (keep in sync): agent table, Typical Workflow tables, and Skills / Prompts tables.
5. Sibling skill descriptions: `Do NOT use for … (prefer <name>)` clauses pointing at the removed entity.
6. Handoffs sections in other skills and agents: delete dead `→` lines pointing at the removed entity (skills are downstream-only, so there are no `←` lines to clean).
7. The owning agent's Skill Activation table; when merging, re-route the removed skill's trigger phrases to the absorbing skill.
8. Run validator: `bash .github/scripts/validate-style-guide.sh`

Broken paths silently degrade Copilot output — they do not error.

### STYLE-GUIDE Changes

This file is the canonical source. When updating format rules:

1. Update STYLE-GUIDE.md **first**.
2. Identify affected files: `grep -rn "<changed-pattern>" .github/`
3. Update all affected files to comply with the new rules in the **same PR**.
4. Update `validate-style-guide.sh` if the change introduces a new machine-checkable rule.
5. Never change the STYLE-GUIDE without propagating — a rule that only exists here and not in the files is worse than no rule.
