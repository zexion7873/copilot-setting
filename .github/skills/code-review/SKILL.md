---
name: code-review
description: 'Use when user wants code reviewed for correctness, style, bugs, and maintainability. Triggers on: review code, code review, check this code, review PR, 審查程式碼, 幫我看程式碼, review 一下, 檢查程式碼. Produces severity-classified findings with a verdict. Do NOT use for security-focused audit (prefer security-audit), SQL-focused review (prefer sql-review), or SDD review (prefer sdd-review).'
---

# Code Review — Workflow

Structured code review. Severity model and checklist: `prompts/code-review-checklist.prompt.md`.

Full coding rules in `instructions/*.instructions.md`. Key rules:

- **Java 8 only**: no 9+ syntax — see `instructions/java.instructions.md`
- **Hibernate/Spring**: `getCurrentSession()`, `<tx:advice>`, no annotations — see `instructions/spring-hibernate.instructions.md`
- **SQL**: parameterized only — see `instructions/sql.instructions.md`
- **Security**: OWASP essentials — see `instructions/security.instructions.md`

## Phase 1 — Understand the Change

1. Read the diff / files under review
2. Understand the intent: what problem does this solve?
3. Check if the approach matches existing patterns

## Phase 2 — Review by Category

Check each category from `prompts/code-review-checklist.prompt.md`:
- **Correctness**: logic errors, edge cases, null handling
- **Security**: injection, auth, data exposure
- **Performance**: N+1, missing indexes, unbounded queries
- **Maintainability**: naming, duplication, complexity
- **Convention compliance**: Java 8 rules, Spring/Hibernate patterns

## Phase 3 — Classify Findings

| Severity | Definition | Action |
|---|---|---|
| 🔴 CRITICAL | Security vulnerability, data loss, crash | Must fix before merge |
| 🟠 MAJOR | Bug, performance issue, convention violation | Should fix |
| 🟡 MINOR | Style, naming, minor improvement | Nice to fix |
| ⚪ NIT | Preference, trivial | Optional |

## Phase 4 — Verdict

```
## Verdict: APPROVE / REQUEST CHANGES / NEEDS DISCUSSION
Findings: N critical, N major, N minor, N nit
Summary: <one-sentence overall assessment>
```

## Handoffs

- → `@implementer` — to fix findings
- → `security-audit` skill — if security concerns warrant deeper audit
- → `sql-review` skill — if SQL issues warrant dedicated review
- ← `@reviewer` — default activation
