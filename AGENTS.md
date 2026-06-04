<!-- Generated: 2026-06-03 | Updated: 2026-06-03 -->

# copilot-setting

## Purpose
A **configuration distribution for GitHub Copilot** — not application code. It ships a multi-agent system (agents, skills, instructions, prompts, hooks) that teaches Copilot how to work in downstream **Java 8 / Maven / Spring Core 3.2 + Hibernate 4.2** projects (no Spring Boot; declarative transactions via XML `<tx:advice>`). Everything meaningful lives under `.github/`, which Copilot loads at runtime. There is no build, no test suite, and no runtime — only Markdown prompt-engineering artifacts and one validation script.

> This file is a condensed, agent-agnostic index. The authoritative, Claude-specific guidance is `CLAUDE.md`; the authoritative format spec is `.github/STYLE-GUIDE.md`. Read those before editing.

## Top-Level Files
| File | Description |
|------|-------------|
| `CLAUDE.md` | Authoritative guidance for AI agents editing this repo — architecture, separation-of-concerns rules, maintenance protocols |
| `CONTRIBUTING.md` | PR workflow: branch from `main`, follow STYLE-GUIDE, run inbound-reference grep, run validator |
| `README.md` / `README.zh-TW.md` | Project overview (English + Traditional Chinese) — keep in sync |
| `SECURITY.md` | Security policy and disclosure process |

## The `.github/` Layout
Five categories with **strict separation of concerns** — each has exactly one job; content belonging to another category is *referenced*, never copied. The runtime pipeline:

```text
Hooks ──lifecycle guard──→ Agent (Router)
                             └──activates──→ Skill (Workflow + Output Template)
                                                  └──rules──→ Instruction (Rules)
Prompt (Shortcut) ──manual /prompt-name──→ Standalone execution
```

| Path | Role | Loads when |
|------|------|------------|
| `.github/agents/*.agent.md` | Routers — activate workflows, manage handoffs (5: planner, implementer, reviewer, debugger, researcher) | User types `@agent-name` |
| `.github/skills/<name>/SKILL.md` | Step-by-step workflows with embedded output templates (13 skills) | Intent match or `/skill-name` |
| `.github/instructions/*.instructions.md` | Single source of truth for coding conventions (8 files) | A file matching its `applyTo` glob is in context; `applyTo: "**"` always loads |
| `.github/prompts/*.prompt.md` | Lightweight single-task shortcuts (5) | Manual `/prompt-name` |
| `.github/hooks/` | Fail-closed pre-tool-use guard blocking dangerous shell commands | Agent tool-use events |
| `.github/scripts/validate-style-guide.sh` | The only executable workflow — format validator | Run manually / pre-commit / CI |
| `.github/workflows/validate-style-guide.yml` | GitHub Actions CI running the validator | PR touching `.github/**/*.md`, the validator script, hooks, or the workflow |
| `.github/STYLE-GUIDE.md` | Authoritative format spec for every file under `.github/` | Read before any structural edit |

> Not part of the product (ignored state / dependencies / IDE config): `.omc/`, `.omo/`, `.claude/`, `.codegraph/`, `.sisyphus/`, `.idea/`, `.vscode/`.

## For AI Agents

### Working In This Directory
- You are editing **prompt-engineering artifacts**, not source code. Words are the product.
- Read `.github/STYLE-GUIDE.md` **before** adding or restructuring any agent / skill / instruction. Format changes update STYLE-GUIDE.md *first*, then propagate.
- **Separation-of-concerns is the prime directive.** Skills embed their own output templates; instructions hold rules only; skills never duplicate instruction rule-lists — except the one sanctioned exception: hard-boundary version locks (Java 8 / Spring 3.2 / Hibernate 4.2 / SQL / security) embedded in code-touching agent bodies (`implementer`, `reviewer`, `debugger`) under `## Coding Standards`.
- Cross-references use backtick-wrapped **relative paths from `.github/`** (e.g. `` `instructions/sql.instructions.md` ``), never bare names.
- Before renaming/moving any file under `.github/`, grep for inbound references — broken paths silently degrade Copilot output (they don't error, they just stop loading).
- Batch edits to `instructions/`, `agents/`, `skills/` — they sit in Copilot's prompt cache; frequent small edits cost more (cache-write churn) than they save.

### Testing Requirements
- The only executable workflow:
  ```bash
  bash .github/scripts/validate-style-guide.sh
  ```
- Run before committing any `.github/` change. CI enforces it on PRs touching `.github/**/*.md`, the validator script, `.github/hooks/**`, or the workflow file.
- One-time local setup so it also runs on `git commit`: `git config core.hooksPath .githooks`

### Common Patterns
- **Bilingual split**: all `.github/` content is English (Copilot may inject it into any user's prompt); chat replies to downstream users are Traditional Chinese; README has synced English + zh-TW versions.
- **Conventional Commits** for all commit messages (see `.github/skills/git-commit/SKILL.md` — manual-only via `/git-commit`).

## Dependencies

### External
- **GitHub Copilot** — the runtime that loads everything under `.github/`
- `bash` + `jq` — required by the validator and the dangerous-command hook (hook is fail-closed without `jq`)
- **GitHub Actions** — CI enforcement

<!-- MANUAL: Custom project notes can be added below -->
