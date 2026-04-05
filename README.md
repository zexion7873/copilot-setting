# Global GitHub Copilot Configuration

**English** | [繁體中文](README.zh-TW.md)

[![License: MIT](https://img.shields.io/github/license/zexion7873/copilot-setting?style=flat)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/stargazers)
[![Last commit](https://img.shields.io/github/last-commit/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/commits)
[![GitHub issues](https://img.shields.io/github/issues/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/issues)
[![Repo size](https://img.shields.io/github/repo-size/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting)

Personal Copilot settings. All files except `copilot-instructions.md` are based on [awesome-copilot](https://github.com/github/awesome-copilot), customized as needed.

## Directory Structure

```
~/.github/
├── copilot-instructions.md                ← Global base instructions (custom)
│
├── instructions/                          ← Auto-applied rules based on applyTo pattern
│   ├── code-review-generic
│   ├── context7
│   ├── context-engineering
│   ├── markdown
│   ├── no-heredoc
│   ├── oop-design-patterns
│   ├── performance-optimization
│   ├── security-and-owasp
│   ├── self-explanatory-code-commenting
│   └── sql-sp-generation
│
├── agents/                                ← Invoke via @agent-name in chat
│   ├── planner              (Claude Opus 4.6)
│   ├── implementer          (GPT-5.3-Codex)
│   ├── reviewer             (Claude Opus 4.6)
│   ├── test-designer        (Claude Sonnet 4.6)
│   ├── debugger             (Claude Opus 4.6)
│   ├── refactorer           (Claude Sonnet 4.6)
│   ├── sql-expert           (Claude Sonnet 4.6)
│   ├── doc-writer           (GPT-5 mini)
│   └── security             (Claude Opus 4.6)
│
├── prompts/                               ← Reusable prompt templates
│   ├── context-map
│   ├── conventional-commit
│   ├── create-architectural-decision-record
│   ├── create-implementation-plan
│   ├── create-technical-spike
│   ├── first-ask
│   ├── java-docs
│   ├── java-junit
│   ├── java-refactoring-extract-method
│   ├── java-refactoring-remove-parameter
│   ├── refactor-plan
│   ├── review-and-refactor
│   ├── sql-code-review
│   ├── sql-optimization
│   └── what-context-needed
│
└── skills/                                ← Executable skills for agents
    ├── git-commit/
    └── refactor/
```

---

## copilot-instructions.md (Custom)

Global base instructions loaded in every conversation.

- Respond in Traditional Chinese (繁體中文)
- All comments, variable names, and class names in code must be in English
- Tech stack: Java 8, Maven, no Spring Boot
- Coding style, error handling, git conventions, logging standards

---

## Instructions

Automatically applied based on `applyTo` glob patterns (e.g., `**/*.java`, `**/*.sql`).

| File | Description |
|------|-------------|
| `code-review-generic` | Generic code review checklist customizable for any project |
| `context7` | Use Context7 MCP for authoritative external docs and API references |
| `context-engineering` | Structure code/projects to maximize Copilot effectiveness through better context |
| `markdown` | Markdown formatting aligned to CommonMark spec (0.31.2) |
| `no-heredoc` | Prevent terminal heredoc file corruption — enforce file editing tools over shell redirections |
| `oop-design-patterns` | OOP design patterns (GoF + SOLID) for clean, maintainable, scalable code |
| `performance-optimization` | Comprehensive performance optimization for frontend, backend, and database |
| `security-and-owasp` | Secure coding based on OWASP Top 10 and industry best practices |
| `self-explanatory-code-commenting` | Write self-explanatory code with minimal but meaningful comments |
| `sql-sp-generation` | Guidelines for generating MySQL SQL statements and stored procedures |

---

## Agents (Custom)

Invoke via `@agent-name` in Copilot Chat. All agents are tailored for Java 8 / Maven projects.

| Agent | Model | Description |
|-------|-------|-------------|
| `@planner` | Claude Opus 4.6 | Analyze requirements, break down tasks, estimate impact scope |
| `@implementer` | GPT-5.3-Codex | Write production-ready Java code following established patterns |
| `@reviewer` | Claude Opus 4.6 | Thorough code review: correctness, security, performance, maintainability |
| `@test-designer` | Claude Sonnet 4.6 | Design comprehensive test cases (happy path, edge cases, boundary) |
| `@debugger` | Claude Opus 4.6 | Systematically debug issues by analyzing stack traces and tracing execution |
| `@refactorer` | Claude Sonnet 4.6 | Improve code structure without changing behavior |
| `@sql-expert` | Claude Sonnet 4.6 | SQL writing, optimization, review, and performance analysis |
| `@doc-writer` | GPT-5 mini | Write SDD, Javadoc, API docs, migration guides |
| `@security` | Claude Opus 4.6 | Security review based on OWASP Top 10 for Java web applications |

---

## Prompts

Reusable prompt templates. Invoke via prompt picker or `/` reference.

### Context & Planning

| Prompt | Description |
|--------|-------------|
| `context-map` | Generate a map of all relevant files before making changes |
| `first-ask` | Interactive task refinement — clarify scope, deliverables, constraints before acting |
| `what-context-needed` | Ask Copilot what files it needs before answering |
| `create-implementation-plan` | Create structured implementation plans for features, refactoring, or upgrades |
| `create-technical-spike` | Create time-boxed technical spike documents for critical decisions |
| `create-architectural-decision-record` | Create ADR documents for decision documentation |

### Java

| Prompt | Description |
|--------|-------------|
| `java-docs` | Generate Javadoc comments following best practices |
| `java-junit` | JUnit 5 unit testing best practices including data-driven tests |
| `java-refactoring-extract-method` | Refactoring using Extract Method pattern |
| `java-refactoring-remove-parameter` | Refactoring using Remove Parameter pattern |

### SQL

| Prompt | Description |
|--------|-------------|
| `sql-code-review` | SQL code review for security, maintainability, and quality (MySQL/PostgreSQL/SQL Server/Oracle) |
| `sql-optimization` | SQL performance optimization — query tuning, indexing, execution plan analysis |

### Code Quality & Git

| Prompt | Description |
|--------|-------------|
| `review-and-refactor` | Review and refactor code according to defined instructions |
| `refactor-plan` | Plan multi-file refactors with sequencing and rollback steps |
| `conventional-commit` | Generate standardized conventional commit messages |

---

## Skills

Executable capabilities that agents can invoke.

| Skill | Description |
|-------|-------------|
| `git-commit` | Auto-detect changes, generate conventional commit messages, intelligent staging |
| `refactor` | Surgical code refactoring — extract functions, rename variables, eliminate code smells |
