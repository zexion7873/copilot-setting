---
name: code-review
description: 'Use when user wants code reviewed for correctness, style, bugs, and maintainability. Triggers on: review code, code review, check this code, review PR, 審查程式碼, 幫我看程式碼, review 一下, 檢查程式碼. Produces severity-classified findings with a verdict. Do NOT use for security-focused audit (prefer security-audit), SQL-focused review (prefer sql-review), or SDD review (prefer sdd-review).'
---

# Code Review — Workflow

Structured code review. Checklist: `prompts/code-review-checklist.prompt.md`.

Full coding rules in `instructions/*.instructions.md`. Key rules:

- **Java 8 only**: no 9+ syntax — see `instructions/java.instructions.md`
- **Hibernate/Spring**: `getCurrentSession()`, `<tx:advice>`, no annotations, no `@RestController` — see `instructions/spring-hibernate.instructions.md`
- **SQL**: parameterized only — see `instructions/sql.instructions.md`
- **Security**: OWASP essentials — see `instructions/security.instructions.md`

## What to Check

- **Correctness**: logic errors, edge cases, null handling, resource leaks
- **Security**: injection, auth, data exposure, hardcoded secrets
- **Performance**: N+1, missing indexes, unbounded queries
- **Conventions**: Java 8 rules, Spring 3.2/Hibernate 4.2 patterns, SLF4J logging
- **Maintainability**: naming, duplication, complexity, comments explain WHY

## Severity

| Level | Definition | Action |
|---|---|---|
| 🔴 CRITICAL | Security vuln, data loss, crash | Must fix before merge |
| 🟠 MAJOR | Bug, perf issue, convention violation | Should fix |
| 🟡 MINOR | Style, naming, minor improvement | Nice to fix |
| ⚪ NIT | Preference, trivial | Optional |

## Output

```
## Verdict: APPROVE / REQUEST CHANGES / NEEDS DISCUSSION
Findings: N critical, N major, N minor, N nit
Summary: <one-sentence assessment>
```

Per finding: `[SEVERITY] Category — description @ file:line → suggestion`

## Handoffs

- → `@implementer` — to fix findings
- → `security-audit` skill — security concerns warrant deeper audit
- → `sql-review` skill — SQL issues warrant dedicated review
- ← `@reviewer` — default activation
