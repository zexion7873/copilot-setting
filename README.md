<div align="center">

# Copilot Agentic Context Engineering

**English** | [繁體中文](README.zh-TW.md)

[![License: MIT](https://img.shields.io/github/license/zexion7873/copilot-setting?style=flat)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/stargazers)
[![Last commit](https://img.shields.io/github/last-commit/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/commits)
[![GitHub issues](https://img.shields.io/github/issues/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/issues)
[![Repo size](https://img.shields.io/github/repo-size/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting)

</div>

Agentic context engineering for GitHub Copilot — agents route, skills execute, instructions enforce, hooks guard.

---

## 🚀 Quick Start

### Option A — Single Project

Copy the `.github/` directory into your project root:

```text
your-java-project/
├── .github/          ← paste here
├── src/
├── pom.xml
└── ...
```

Copilot picks it up automatically — agents, skills, instructions, hooks, all active.

### Option B — Workspace-Wide

Add this repository as a folder in a VS Code [multi-root workspace](https://code.visualstudio.com/docs/editor/multi-root-workspaces). Every project in the workspace shares the configuration.

```text
my-workspace.code-workspace
├── copilot-setting/      ← this repo
├── project-a/
├── project-b/
└── ...
```

---

## ⚙️ How It Works

Just pick an **agent** — everything else loads automatically.

|   | Category | Role | Responsibility | When it loads |
|:-:|---|---|---|---|
| 📏 | **Instructions** (`instructions/`) | Rules | Single source of truth for conventions | `applyTo` glob matches a file in request context; core rules also embedded in code-touching agents |
| 🤖 | **Agents** (`agents/`) | Router | Activate workflows, manage handoffs | `@agent-name` in chat |
| ⚡ | **Skills** (`skills/`) | Workflow | Execution steps — reference rules and templates | Matches `description`; Skill Activation routes |
| 📋 | **Prompts** (`prompts/`) | Shortcut | Lightweight single-task commands | Manual invocation (`/prompt-name`) |
| 🛡️ | **Hooks** (`hooks/`) | Lifecycle guard | Block dangerous commands before execution | Agent tool use events |

Each category has one job. Content that belongs elsewhere is referenced, not copied.

```mermaid
flowchart LR
    Hook["🛡️ Hooks"] -->|lifecycle guard| Agent
    Agent["🤖 Agent<br/>(Router)"] -->|activates| Skill
    Skill["⚡ Skill<br/>(Workflow + Output Template)"] -->|rules| Instruction["📏 Instruction<br/>(Rules)"]
    Prompt["📋 Prompt<br/>(Shortcut)"] -->|"manual /prompt-name"| Standalone["Standalone execution"]
```

> [!NOTE]
> **Agent chat caveat:** `applyTo` instructions load only when a matching file is in the request context (attached via `#file:` or the editor), evaluated at request time — files the agent reads mid-task do not retroactively trigger them. To cover `@agent` use without an attached file, the hard-boundary rules are embedded directly in the code-touching agent bodies under `## Coding Standards`; code-touching skills additionally name the instruction files they map to.

> [!TIP]
> **Maintenance rule:** before renaming or moving any file under `.github/`, run `grep -rn "<old-filename>" .github/` to find inbound references. Broken paths silently degrade Copilot output.

---

## 🤖 Agents

Invoke via `@agent-name` in Copilot Chat. All agents are tailored for Java 8 / Maven projects.

|   | Agent | Model | Description |
|:-:|-------|-------|-------------|
| 📐 | `@planner` | Claude Opus 4.6 | Activates `plan` / `tasks` / `clarify-task` skills; plans and task decomposition in one agent |
| 🔨 | `@implementer` | GPT-5.3-Codex | Activates `implement` / `refactor` / `test-design` / `performance` skills, mode-routed by trigger phrase |
| 🔍 | `@reviewer` | Claude Sonnet 4.6 | Activates `code-review` / `security-audit` / `sql-review` / `schema-migration-review` skills, mode-routed by review type |
| 🐛 | `@debugger` | Claude Sonnet 4.6 | Activates `debug` skill — hypothesis ranking, binary-search isolation, minimal fix proposal |
| 📚 | `@researcher` | Claude Haiku 4.5 | Lightweight read-only subagent for `@planner`, `@implementer`, and `@reviewer` — searches codebase and external docs, returns structured summaries — no opinions or recommendations |

### 🤝 Agent Handoffs Workflow

Agents can hand off tasks to each other, forming a collaborative workflow:

```mermaid
flowchart LR
    Planner["📐 Planner"] -->|"Implement"| Implementer
    Planner -->|"Security assessment"| Reviewer

    Implementer["🔨 Implementer"] -->|"Code review"| Reviewer
    Implementer -->|"Security review"| Reviewer
    Implementer -->|"Debug"| Debugger
    Implementer -->|"Re-plan"| Planner

    Reviewer["🔍 Reviewer"] -->|"Fix issues"| Implementer
    Reviewer -->|"Refactor"| Implementer
    Reviewer -->|"Debug"| Debugger
    Reviewer -->|"Re-plan"| Planner

    Debugger["🐛 Debugger"] -->|"Fix bug"| Implementer

    Implementer -.->|"subagent"| Researcher["📚 Researcher"]
    Planner -.->|"subagent"| Researcher
    Reviewer -.->|"subagent"| Researcher
```

---

## 🔄 Typical Workflow

Each `→` is a handoff button in VS Code — click it and the next agent inherits the full conversation context. Every path finishes with `/git-commit` (invoke it manually; it never auto-triggers).

### 📐 `@planner` — Start here for new features

| Skill | What it does | Then hand off to |
|---|---|---|
| `clarify-task` | Ask numbered questions to refine vague requirements | stay in `@planner` |
| `plan` | Create phased implementation plan with risks and dependencies | stay in `@planner` |
| `tasks` | Break approved plan into atomic, dependency-ordered tasks | → `@implementer` |

> [!TIP]
> Skip `@planner` for small changes (1–3 files) — go straight to `@implementer`.

### 🔨 `@implementer` — Write and change code

| Skill | What it does | Then hand off to |
|---|---|---|
| `implement` | Implement feature tasks or fix review findings | → `@reviewer` |
| `refactor` | Behavior-preserving structural improvements | → `@reviewer` |
| `test-design` | Design test case document (categories, boundaries, coverage gaps) | → `@reviewer` |
| `performance` | Measure-first performance tuning (frontend / Java / DB) | → `@reviewer` |

### 🔍 `@reviewer` — Review and audit

| Skill | When to use | Then hand off to |
|---|---|---|
| `code-review` | General code review — correctness, style, bugs | → `@implementer` (fix) |
| `security-audit` | OWASP Top 10 focused security audit | → `@implementer` (fix) |
| `sql-review` | SQL injection, index strategy, query anti-patterns | → `@implementer` (fix) |
| `schema-migration-review` | DDL/DML rollback safety, lock impact, deploy compat | → `@implementer` (fix) |


> [!WARNING]
> Every finding is graded CRITICAL / HIGH / MEDIUM / LOW. Never merge with an open CRITICAL or HIGH.
> If review uncovers a deeper bug → `@debugger`. If design-level rework is needed → `@planner`.

### 🐛 `@debugger` — Diagnose bugs

| Skill | What it does | Then hand off to |
|---|---|---|
| `debug` | Reproduce → hypothesize → isolate → verify root cause → propose minimal fix | → `@implementer` (fix) |

> [!NOTE]
> `@debugger` diagnoses only — it does not implement fixes. Always hand off to `@implementer`.

### 📚 `@researcher` — Read-only subagent (automatic)

Not invoked manually. Auto-delegated by `@planner`, `@implementer`, and `@reviewer` to scan the codebase and external docs before acting. Returns structured summaries — no opinions or recommendations.

---

## ⚡ Skills

Executable workflows. Auto-triggered by Copilot when relevant (unless disabled), or invoke manually via `/skill-name`.

|   | Skill | Trigger | Description |
|:-:|-------|---------|-------------|
| ❓ | `clarify-task` | Auto + Manual | Interactive task refinement — numbered clarifying questions before acting |
| 📐 | `plan` | Auto + Manual | Implementation plan — phases, requirements, files, risks (hands off atomic tasks to `tasks` skill) |
| ☑️ | `tasks` | Auto + Manual | Dependency-ordered atomic task breakdown (T### IDs, [P] markers) after plan is approved |
| 🔨 | `implement` | Auto + Manual | Feature implementation — pattern discovery, convention compliance, self-verification |
| ♻️ | `refactor` | Auto + Manual | Surgical refactoring — extract, rename, eliminate smells |
| 🧪 | `test-design` | Auto + Manual | Test case document design — boundary identification, category classification, coverage gap audit (produces documentation, not test code) |
| 📦 | `git-commit` | **Manual only** | [Conventional Commits](https://www.conventionalcommits.org/) message generation and intelligent staging |
| 🔍 | `code-review` | Auto + Manual | Structured code review — correctness, style, bug patterns |
| 🛡️ | `security-audit` | Auto + Manual | OWASP Top 10 audit with severity classification |
| 🗄️ | `sql-review` | Auto + Manual | SQL review — injection prevention, index strategy, anti-patterns |
| 🔄 | `schema-migration-review` | Auto + Manual | DDL/DML migration review — rollback safety, lock impact, backward compatibility |

| 🐛 | `debug` | Auto + Manual | Systematic debugging with hypothesis ranking and isolation |
| ⚡ | `performance` | Auto + Manual | Measure-first performance tuning across frontend, Java backend, and DB |

> [!WARNING]
> `git-commit` uses `disable-model-invocation: true` to prevent auto-triggering. Always invoke explicitly via `/git-commit`.

---

## 📋 Prompts

Lightweight shortcuts. Invoke via `/prompt-name` in Copilot Chat.

| Prompt | Description |
|--------|-------------|
| `/explain-this` | Explain selected code in Traditional Chinese — role, design decisions, gotchas |
| `/find-impact` | List all callers and dependents of the selected method/class |
| `/check-n-plus-1` | Check a service method for N+1 query problems |
| `/generate-migration-sql` | Generate MySQL migration + rollback scripts from hbm.xml changes |
| `/check-tx` | Verify transaction boundary correctness (self-invocation, rollback-for, read-only) |

---

## 📏 Instructions

Automatically injected into the system prompt when the current file matches the `applyTo` glob.

| File | applyTo | Description |
|------|---------|-------------|
| `java` | `**/*.java` | Java 8 language boundary, exception handling, SLF4J logging, and code style — focuses on what AI models get wrong by default. |
| `spring-hibernate` | `**/*.java, **/*.hbm.xml` | Spring Core + Hibernate 4.x — native Session API, hbm.xml mappings, `getCurrentSession()` lifecycle, XML `<tx:advice>` transactions. The most critical file. |
| `sql` | `**/*.java, **/*.sql, **/*.xml` | SQL injection prevention, performance pitfalls, JDBC resource handling, and MySQL stored procedure conventions. |
| `security` | `**/*.java, **/*.jsp` | OWASP Top 10 essentials for Java web applications. |
| `jsp` | `**/*.jsp` | JSP conventions — XSS prevention via `<c:out>`, JSTL-only policy, output encoding. |
| `xml-config` | `**/*.xml` | Spring XML config, Hibernate hbm.xml, and Maven POM conventions. |
| `no-heredoc` | `**` | Forbid terminal heredoc / redirection for writing file content; use file editing tools instead. |

---

## 📜 copilot-instructions.md

Minimal global rules loaded in every conversation. Language, tech stack, and coding philosophy — all other conventions live in dedicated instruction files.

- Respond in Traditional Chinese (繁體中文)
- Tech stack: Java 8, Maven, Spring 3.2, Spring Security 3.2, Hibernate 4.2, MySQL 8.0, JSP + JSTL 1.2
- Coding philosophy: think before coding (surface assumptions, don't guess), simplicity first (no speculative abstractions), surgical changes (touch only what the task requires)

---

<details>
<summary><h2>📁 .github/ Directory Structure</h2></summary>

```text
.github/
├── copilot-instructions.md                ← Global base instructions
│
├── instructions/                          ← Auto-applied rules based on applyTo pattern
│   ├── java.instructions.md
│   ├── spring-hibernate.instructions.md
│   ├── sql.instructions.md
│   ├── security.instructions.md
│   ├── jsp.instructions.md
│   ├── xml-config.instructions.md
│   └── no-heredoc.instructions.md
│
├── agents/                                ← Invoke via @agent-name in chat
│   ├── planner.agent.md              (Claude Opus 4.6)
│   ├── implementer.agent.md          (GPT-5.3-Codex)
│   ├── reviewer.agent.md             (Claude Sonnet 4.6)
│   ├── debugger.agent.md             (Claude Sonnet 4.6)
│   └── researcher.agent.md           (Claude Haiku 4.5)
│
├── hooks/                                 ← Shell commands at agent lifecycle events
│   ├── default.json
│   └── scripts/
│       └── block-dangerous-commands.sh
│
├── prompts/                               ← Lightweight single-task shortcuts (/prompt-name)
│   ├── explain-this.prompt.md
│   ├── find-impact.prompt.md
│   ├── check-n-plus-1.prompt.md
│   ├── generate-migration-sql.prompt.md
│   └── check-tx.prompt.md
│
└── skills/                                ← Executable skills for agents (output templates embedded)
    ├── clarify-task/
    ├── plan/
    ├── tasks/
    ├── implement/
    ├── refactor/
    ├── test-design/
    ├── git-commit/
    ├── code-review/
    ├── security-audit/
    ├── sql-review/
    ├── schema-migration-review/
    ├── debug/
    └── performance/
```

</details>
