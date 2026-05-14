<div align="center">

# GitHub Copilot Configuration

**English** | [繁體中文](README.zh-TW.md)

[![License: MIT](https://img.shields.io/github/license/zexion7873/copilot-setting?style=flat)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/stargazers)
[![Last commit](https://img.shields.io/github/last-commit/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/commits)
[![GitHub issues](https://img.shields.io/github/issues/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/issues)
[![Repo size](https://img.shields.io/github/repo-size/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting)

</div>

A multi-agent Copilot configuration — agents activate workflows, skills define processes, instructions enforce conventions, and prompts standardize output formats.

---

## ⚙️ How It Works

Just pick an **agent** — everything else loads automatically.

| Category | Role | Responsibility | When it loads |
|---|---|---|---|
| **Instructions** (`instructions/`) | Rules | Single source of truth for coding conventions | File matches `applyTo` glob; skills cite via fallback rules |
| **Agents** (`agents/`) | Router | Who I am, which workflows I activate, who I hand off to | `@agent-name` in chat |
| **Skills** (`skills/`) | Workflow | Step-by-step process — references rules and templates, never rewrites them | Copilot matches `description`; agent routes via Skill Activation |
| **Prompts** (`prompts/`) | Template | Output format scaffolds — referenced by workflows | Paired skill references via cross-ref |
| **Hooks** (`hooks/`) | Lifecycle guard | Block dangerous commands before execution | Agent tool use events |

Resources reference each other to avoid duplication — each category has one job, content that belongs elsewhere is delegated, not copied.

```text
Hooks ──lifecycle guard──→ Agent (Router)
                             │
                             └──activates──→ Skill (Workflow) ──output format──→ Prompt (Template)
                                                  │
                                                  └──rules──→ Instruction (Rules)
```

> [!NOTE]
> **Agent chat caveat:** Instructions only auto-load when a matching file is focused in the editor. In `@agent` chat without a matching file open, file-type rules (e.g., `sql-rules`, `error-handling`) may not be injected. To compensate, code-touching skills (`implement`, `refactor`, `code-review`, `sql-review`, `performance`, `debug`) include inline **fallback rules** for critical conventions — these apply regardless of which file is focused.

> [!TIP]
> **Maintenance rule:** before renaming or moving any file under `.github/`, run `grep -rn "<old-filename>" .github/` to find inbound references. Broken paths silently degrade Copilot output.

---

## 🔄 Typical Workflow

Example: adding a new API endpoint.

```text
You  →  @planner       "I need an API to query order history by customer ID"
                        Planner scans the codebase, drafts a phased plan,
                        then writes a formal SDD (spec) with acceptance criteria
                        ↓ click "開始實作" handoff

You  →  @implementer   Picks up the SDD, writes code following existing patterns
                        ↓ click "Code Review" handoff

You  →  @reviewer      Checks correctness, security, performance
                        Catches SQL injection risk → CRITICAL
                        ↓ click "Fix issues" handoff

You  →  @implementer   Switches to PreparedStatement, writes tests
                        Done ✓
```

Each `↓` is a handoff button in VS Code. The next agent gets the full conversation context.

> [!TIP]
> **Other common starting points:**
>
> - Bug → `@debugger` → `@implementer`
> - Slow SQL → `@reviewer` (SQL review mode) → `@implementer`
> - Security → `@reviewer` (security audit mode) → `@implementer`
> - Spec review → `@reviewer` (SDD review mode) → `@planner`
> - Research → `@planner` (spike mode) → `@planner` (plan mode)
> - Documentation → `@planner`

### 📝 Amendment Workflow

When an existing SDD needs revision mid-implementation (new requirements, API contract changes, schema bumps), the `sdd` skill enters **Phase 0 — Amendment Gate** instead of rewriting from scratch:

```mermaid
flowchart LR
    SDD[Existing SDD] --> Gate{Phase 0<br/>Amendment Gate}
    Gate --> Bump[Mark changes + rationale<br/>+ semver bump]
    Bump --> Sync[Sync Impact Report<br/>+ §9 Changelog]
    Sync --> Tasks[tasks: re-scope T###]
    Sync --> Impl["@implementer: refactor"]
    Sync --> Comp[sdd-compliance: re-verify]
```

Semver convention: **MAJOR** for breaking changes (removed AC, API contract change, incompatible schema), **MINOR** for additive (new AC, new endpoint, backward-compatible schema), **PATCH** for clarifications. Full procedure in `.github/skills/sdd/SKILL.md`.

---

## 🤖 Agents

Invoke via `@agent-name` in Copilot Chat. All agents are tailored for Java 8 / Maven projects.

<!-- BEGIN:AGENTS_TABLE -->
|   | Agent | Model | Description |
|:-:|-------|-------|-------------|
| 📐 | `@planner` | Claude Opus 4.6 | Activates `plan` / `tasks` / `sdd` / `constitution` / `spike` / `adr` / `clarify-task` skills; plans, specs, and task decomposition in one agent |
| 🔨 | `@implementer` | GPT-5.3-Codex | Activates `implement` / `refactor` / `test-design` / `context-discovery` / `performance` skills, mode-routed by trigger phrase |
| 🔍 | `@reviewer` | Claude Opus 4.6 | Activates `code-review` / `security-audit` / `sql-review` / `sdd-review` / `sdd-compliance` skills, mode-routed by review type |
| 🐛 | `@debugger` | Claude Opus 4.6 | Activates `debug` skill — hypothesis ranking, binary-search isolation, minimal fix with regression test |
| 📚 | `@researcher` | Claude Haiku 4.5 | Lightweight read-only subagent for `@implementer` and `@planner` — searches codebase and external docs, returns structured summaries |
<!-- END:AGENTS_TABLE -->

### 🤝 Agent Handoffs Workflow

Agents can hand off tasks to each other, forming a collaborative workflow:

```mermaid
flowchart LR
    Planner -->|"Review SDD"| Reviewer
    Planner -->|"Implement"| Implementer
    Planner -->|"Security assessment"| Reviewer
    Planner -.->|"subagent"| Researcher

    Implementer -.->|"subagent"| Researcher
    Implementer -->|"Code review"| Reviewer
    Implementer -->|"Security / SQL review"| Reviewer
    Implementer -->|"Debug"| Debugger
    Implementer -->|"Re-plan"| Planner

    Reviewer -->|"Fix issues"| Implementer
    Reviewer -->|"Refactor"| Implementer
    Reviewer -->|"Revise spec"| Planner
    Reviewer -->|"Re-plan"| Planner

    Debugger -->|"Fix bug"| Implementer
```

---

## ⚡ Skills

Executable workflows. Auto-triggered by Copilot when relevant (unless disabled), or invoke manually via `/skill-name`.

<!-- BEGIN:SKILLS_TABLE -->
|   | Skill | Trigger | Description |
|:-:|-------|---------|-------------|
| 📜 | `constitution` | Auto + Manual | Project-wide non-negotiable principles and governance — stable, high-level only (200-line hard limit) |
| ❓ | `clarify-task` | Auto + Manual | Interactive task refinement — numbered clarifying questions before acting |
| 🗺️ | `context-discovery` | Auto + Manual | Pre-action context map — files needed, dependencies, tests, reference patterns |
| 📐 | `plan` | Auto + Manual | Implementation plan — phases, requirements, files, risks (hands off atomic tasks to `tasks` skill) |
| 📌 | `adr` | Auto + Manual | Architectural Decision Record — captures a decision with status, alternatives, and consequences |
| 🔬 | `spike` | Auto + Manual | Time-boxed research document for a single technical question |
| 📄 | `sdd` | Auto + Manual | Spec-Driven Development document — formal spec before implementation (supports amendment with semver versioning) |
| 📋 | `sdd-review` | Auto + Manual | SDD specification review BEFORE implementation — completeness, testability, feasibility, clarity audit |
| ☑️ | `tasks` | Auto + Manual | Dependency-ordered atomic task breakdown (T### IDs, [P] markers) after plan or SDD is approved |
| 🔨 | `implement` | Auto + Manual | Feature implementation with SDD compliance, pattern discovery, and self-verification |
| ✅ | `sdd-compliance` | Auto + Manual | Spec compliance matrix AFTER implementation — verifies every AC has tasks, tests, and code evidence |
| ♻️ | `refactor` | Auto + Manual | Surgical refactoring — extract, rename, eliminate smells |
| 🧪 | `test-design` | Auto + Manual | Test case design — boundary identification, category classification, coverage gap audit; hand off to @implementer for coding |
| 📦 | `git-commit` | **Manual only** | Conventional commit message generation and intelligent staging |
| 🔍 | `code-review` | Auto + Manual | Structured code review — correctness, style, bug patterns (use `sdd-compliance` for AC traceability) |
| 🛡️ | `security-audit` | Auto + Manual | OWASP Top 10 audit with severity classification |
| 🗄️ | `sql-review` | Auto + Manual | SQL review — injection prevention, index strategy, anti-patterns |
| 🐛 | `debug` | Auto + Manual | Systematic debugging with hypothesis ranking and isolation |
| ⚡ | `performance` | Auto + Manual | Measure-first performance tuning across frontend, Java backend, and DB |
<!-- END:SKILLS_TABLE -->

> [!WARNING]
> `git-commit` is marked **manual only** because it modifies git history. Copilot relies on the description text to suppress auto-invocation; always invoke it explicitly via `/git-commit`.

---

## 📏 Instructions

Automatically injected into the system prompt when the current file matches the `applyTo` glob.

<!-- BEGIN:INSTRUCTIONS_TABLE -->
| File | applyTo | Description |
|------|---------|-------------|
| `error-handling` | `**/*.java` | Exception handling and error response conventions for Java 8 — hierarchy, custom exceptions, retry, and error propagation. |
| `global-copilot` | `**` | Language and tech stack base rules: respond in Traditional Chinese, code in English, Java 8 + Maven, no Spring Boot. |
| `logging` | `**/*.java` | SLF4J + Logback logging conventions — severity levels, parameterized messages, context inclusion, and security. |
| `javadoc` | `**/*.java` | Javadoc conventions for Java types and members — tags, formatting, when to document. |
| `jsp` | `**/*.jsp` | JSP template conventions — output encoding, JSTL usage, scriptlet avoidance, and XSS prevention in server-rendered pages. |
| `junit` | `**/*Test.java, **/*IT.java, **/test/**/*.java` | JUnit 5 + Mockito conventions for Java tests — naming, structure, parameterization, assertions. |
| `markdown` | `**/*.md` | Markdown formatting aligned to the CommonMark specification (0.31.2) |
| `no-heredoc` | `**` | Forbid terminal heredoc / redirection for writing file content; use file editing tools instead. Works around VS Code Copilot terminal corruption. |
| `security-and-owasp` | `**/*.java, **/*.jsp` | Secure coding rules for Java web applications based on OWASP Top 10 and industry best practices. |
| `self-explanatory-code-commenting` | `**/*.{java,js,ts,py,cs}` | Write self-explanatory code with minimal comments. Only comment WHY when non-obvious. Applies to any language with comments. |
| `sql-rules` | `**/*.java, **/*.sql, **/*.xml, **/*.jsp` | SQL hard rules covering injection prevention, performance pitfalls, indexing, pagination, and code quality. Single source of truth for SQL across all file types that may contain it. |
| `sql-sp-generation` | `**/*.sql` | MySQL stored procedure and schema generation conventions. General SQL rules live in sql-rules.instructions.md. |
| `xml` | `**/*.xml` | XML conventions for Maven POM, web.xml, and configuration files — structure, formatting, and common pitfalls. |
| `properties` | `**/*.properties` | Java properties file conventions — key naming, organization, encoding, and secret management. |
| `yaml-json-config` | `**/*.yml, **/*.yaml, **/*.json` | YAML and JSON configuration file conventions — formatting, structure, and secret management. |
<!-- END:INSTRUCTIONS_TABLE -->

---

## 📋 Prompts

Standards and output-format references, paired with skills. Invoke via `/prompt-name` in Copilot Chat, or let the paired skill cite them automatically.

<!-- BEGIN:PROMPTS_TABLE -->
| Prompt | Paired skill | Purpose |
|--------|-------------|---------|
| `code-review-checklist` | `code-review` | Severity buckets and what to check by category |
| `sql-review-output` | `sql-review` | Output format reference (severity buckets, EXPLAIN cheat sheet) for the sql-review skill |
| `spec-template` | `sdd` | SDD scaffold — 9 sections from background to changelog |
| `plan-template` | `plan` | Implementation plan scaffold with `REQ-` / `CON-` / `PAT-` / `FILE-` identifiers |
| `tasks-template` | `tasks` | Dependency-ordered `tasks.md` scaffold with T### IDs and `[P]` parallel markers |
| `adr-template` | `adr` | ADR scaffold with Status / Context / Decision / Consequences / Alternatives |
<!-- END:PROMPTS_TABLE -->

> [!NOTE]
> **Naming convention** (suffix indicates content type):
>
> - `*-template` — fill-in scaffold for one-shot artifact creation (e.g., `spec-template`, `plan-template`)
> - `*-checklist` — verification checklist with categorized items (e.g., `code-review-checklist`)
> - `*-output` — output format / cheat-sheet reference cited by its paired skill (e.g., `sql-review-output`)

---

## 📜 copilot-instructions.md

Minimal global rules loaded in every conversation. Only language and tech stack — all other conventions live in dedicated instruction files.

- Respond in Traditional Chinese (繁體中文)
- All comments, variable names, and class names in code must be in English
- Tech stack: Java 8, Maven, no Spring Boot

> [!NOTE]
> **Why does `global-copilot.instructions.md` contain the same content?**
>
> Copilot loads instructions through two independent scopes:
>
> | Scope | Mechanism | File |
> |-------|-----------|------|
> | **Project** | Copilot auto-detects `.github/copilot-instructions.md` in the workspace root | `copilot-instructions.md` |
> | **User** | VS Code `chat.instructionsFilesLocations` points to an instructions folder | `global-copilot.instructions.md` |
>
> There is no user-scope equivalent of `copilot-instructions.md` — VS Code only provides `chat.instructionsFilesLocations` for the `instructions/` folder, not for `copilot-instructions.md` itself. To apply the same base rules across all workspaces, the content must also exist as an `.instructions.md` file with `applyTo: '**'` inside the instructions folder.

---

## 🔧 Maintenance Scripts

Scripts to keep configuration files and README in sync. Requires `bash` + `jq`.

| Command | What it does |
|---------|-------------|
| `bash scripts/sync-readme.sh` | Regenerate README tables and directory tree from frontmatter + `readme-meta.json` |
| `bash scripts/lint-copilot-config.sh` | Validate cross-references (skill ↔ agent binding, file ↔ meta sync) |
| `bash scripts/validate-frontmatter.sh` | Check required frontmatter fields (name, description, triggers, etc.) |

CI runs these automatically — `sync-readme` on push to main, lint + validate on PRs.

---

<details>
<summary><h2>📁 .github/ Directory Structure</h2></summary>

<!-- BEGIN:DIRECTORY_TREE -->
```text
~/.github/
├── copilot-instructions.md                ← Global base instructions
│
├── instructions/                          ← Auto-applied rules based on applyTo pattern
│   ├── error-handling
│   ├── global-copilot
│   ├── logging
│   ├── javadoc
│   ├── jsp
│   ├── junit
│   ├── markdown
│   ├── no-heredoc
│   ├── security-and-owasp
│   ├── self-explanatory-code-commenting
│   ├── sql-rules
│   ├── sql-sp-generation
│   ├── xml
│   ├── properties
│   └── yaml-json-config
│
├── agents/                                ← Invoke via @agent-name in chat
│   ├── planner              (Claude Opus 4.6)
│   ├── implementer          (GPT-5.3-Codex)
│   ├── reviewer             (Claude Opus 4.6)
│   ├── debugger             (Claude Opus 4.6)
│   └── researcher           (Claude Haiku 4.5)
│
├── hooks/                                 ← Shell commands at agent lifecycle events
│   ├── default.json
│   └── scripts/
│       └── block-dangerous-commands.sh
│
├── prompts/                               ← Standards/format references paired with skills
│   ├── code-review-checklist
│   ├── sql-review-output
│   ├── spec-template
│   ├── plan-template
│   ├── tasks-template
│   └── adr-template
│
└── skills/                                ← Executable skills for agents
    ├── constitution/
    ├── clarify-task/
    ├── context-discovery/
    ├── plan/
    ├── adr/
    ├── spike/
    ├── sdd/
    ├── sdd-review/
    ├── tasks/
    ├── implement/
    ├── sdd-compliance/
    ├── refactor/
    ├── test-design/
    ├── git-commit/
    ├── code-review/
    ├── security-audit/
    ├── sql-review/
    ├── debug/
    └── performance/
```
<!-- END:DIRECTORY_TREE -->

</details>
