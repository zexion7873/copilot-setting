# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A VS Code GitHub Copilot configuration repository. The contents under `.github/` mirror the layout of `~/.github/` for global Copilot settings — copying or symlinking deploys it. There is **no build, lint, test, or compile step**; everything here is markdown configuration consumed by VS Code Copilot at conversation time.

The target consumer is **VS Code Copilot only**, not Claude Code. See "Target consumer" below.

## Resource taxonomy

Four resource types under `.github/`, each with distinct loading semantics. **Picking the right type is the central design decision when adding content.**

| Type | Folder | Loaded when | Trigger | Use for |
|---|---|---|---|---|
| `copilot-instructions.md` | `.github/` (single file) | Every conversation | Always | Global base rules for the whole project |
| `instructions/*.instructions.md` | `.github/instructions/` | Current file matches `applyTo` glob | File-scope auto-injection | Static rules tied to file types (Java, SQL, Markdown, etc.) |
| `agents/*.agent.md` | `.github/agents/` | User types `@agent-name` | Manual only | Role-specific personas with tailored model/scope |
| `prompts/*.prompt.md` | `.github/prompts/` | User types `/prompt-name` | Manual only | Reusable templates with fill-in variables |
| `skills/<name>/SKILL.md` | `.github/skills/` | Auto-trigger on description match, OR `/skill-name` | Auto + Manual | Multi-step workflows |

**Decision rule when adding new content:**
- File-type rule → `instructions/` (auto-applies, no friction)
- Multi-step procedure → `skills/` (auto-triggers when relevant)
- One-shot template needing variables → `prompts/`
- Persona / model selection → `agents/`

## Cross-references between resources

Skills, prompts, and instructions reference each other by **relative path within `.github/`** to avoid duplication. The conventional pairing is:

- A `skills/<x>/SKILL.md` defines the **workflow** (order of attack, phases, verdict shape)
- A paired `instructions/<x>.instructions.md` defines the **rules** (what's allowed/forbidden, single source of truth)
- An optional `prompts/<x>.prompt.md` defines the **output format** or **standards reference**

Examples in the codebase:
- `skills/code-review/` ↔ `prompts/code-review-checklist.prompt.md`
- `skills/sql-review/` ↔ `instructions/sql-rules.instructions.md` + `prompts/sql-review-output.prompt.md`
- `skills/security-audit/` ↔ `instructions/security-and-owasp.instructions.md`
- `skills/refactor/` ↔ `skills/refactor/examples/{extract-method,remove-parameter}.md`

**Before renaming or moving any file under `.github/`, grep for inbound references first** — broken paths in skill instructions silently degrade Copilot output:

```bash
grep -rn "<old-filename>" .github/
```

## Target consumer (important)

This repo is **for VS Code Copilot, not Claude Code**. Claude Code-only frontmatter fields have been deliberately removed:

- ❌ `context: fork` — Claude Code subagent isolation; Copilot ignores it silently
- ❌ `disable-model-invocation: true` — Claude Code hard-blocks auto-invocation; Copilot ignores it

If you add a new skill, **do not re-introduce these fields** even though Copilot tolerates them — they create false expectations.

To prevent auto-invocation in Copilot (e.g., for `git-commit` which writes history), the only mechanism available is **strong language in the `description` field itself**: phrases like `MANUAL ONLY — invoke explicitly via /skill-name` and `NEVER auto-trigger from conversational mentions`. See `.github/skills/git-commit/SKILL.md` for the canonical pattern.

## Frontmatter conventions per resource type

**`instructions/*.instructions.md`:**
```yaml
---
description: '...'
applyTo: '**/*.java, **/*.sql'   # comma-separated globs
---
```

**`skills/<name>/SKILL.md`:**
```yaml
---
name: <skill-name>
description: 'Use when ... Triggers on: <English phrases>, <繁中觸發詞>. Does X. Do NOT use for ...'
---
```
The `description` is **the only mechanism Copilot uses to decide auto-trigger** — every skill description in this repo includes English triggers, Traditional Chinese triggers, and explicit "Do NOT use for" anti-cases. Match this pattern when adding skills.

**`agents/*.agent.md` and `prompts/*.prompt.md`:** see existing files for shape; both are manual-trigger so frontmatter is less load-bearing.

## Coding standards Copilot enforces

`.github/copilot-instructions.md` is loaded into every conversation. Key constraints (do not contradict in skill / instruction content):

- **Stack**: Java 8 + Maven, no Spring Boot (Java SE / Jakarta EE conventions)
- **Language split**: replies in Traditional Chinese; all code identifiers, comments, Javadoc, commit messages in English
- **Conventional Commits** for git messages
- **SLF4J + Logback** with parameterized logging
- **PreparedStatement only** for SQL — never string concatenation

When writing examples in skills/instructions, target Java 8 syntax (no records, no `var`, no switch expressions).

## When adding a new skill

1. Create `.github/skills/<name>/SKILL.md` with the frontmatter shape above
2. The `description` MUST include both English and Traditional Chinese trigger phrases plus a "Do NOT use for" clause
3. If the skill needs supporting examples or sub-docs, put them under `.github/skills/<name>/<file>.md` and reference from SKILL.md by relative path — they only load when SKILL.md cites them
4. Update both `README.md` and `README.zh-TW.md` Skills tables together
5. Decide consciously: if there's overlap with an existing skill, write a "Do NOT use" disambiguation in both descriptions

## When adding a new instruction

1. Create `.github/instructions/<name>.instructions.md` with `applyTo` glob
2. Existing `applyTo` patterns in use (avoid creating near-duplicates):
   - `**` — global
   - `**/*.java`, `**/*.{java,jsp}`, `**/*Test.java, **/*IT.java, **/test/**/*.java`
   - `**/*.sql`, `**/*.{java,sql,xml,jsp}`
   - `**/*.md`, `**/*.{py,java,ts,js,cs}`
3. Update both READMEs' Instructions tables

## Useful inspection commands

```bash
grep -h "^applyTo:" .github/instructions/*.md | sort -u   # survey applyTo coverage
grep -rn "context: fork\|disable-model-invocation" .github/skills/   # should return nothing
grep -rn "<filename>" .github/   # find inbound references before rename
```
