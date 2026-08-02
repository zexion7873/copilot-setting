---
name: code-review
description: 'Use when user wants code reviewed for correctness, style, bugs, and maintainability. Triggers on: review code, code review, check PR, 審查程式碼, 檢查程式碼. Produces severity-classified findings with a verdict. Do NOT use for security-focused audit (prefer security-audit) or SQL-focused review (prefer sql-review).'
---

# Code Review — Workflow

Structured code review.

## Phase 0 — Load canonical rules

**MANDATORY pre-load gate — do NOT render a verdict (Phase 5) until you have opened the stack instruction modules for the layers under review.** Your training data defaults to the newest idioms; the files under `instructions/` are this project's stack modules — its version lock and house rules. List that directory, then open every module covering the layers this change touches (include the testing module when tests are in scope — it sanctions carve-outs the floor does not mention) — the negative lists in the agent body are a floor, not the full rules.

Read-back receipt (self-check, not machine-enforced): before leaving this step, NAME each module you opened and QUOTE the single most load-bearing rule from each that applies to this change — a generic restatement you could have written from memory means you skipped the file, so open it for real.

## Phase 1 — Understand the Change

1. Read the diff / files under review
2. Understand the intent: what problem does this solve?
3. Check if the approach matches existing patterns

## Phase 2 — Review by Category

**Correctness** (check each):
- [ ] Shared mutable state accessed from multiple threads → synchronized or thread-local?
- [ ] External resources (connections, statements, cursors, streams) released via the stack's ownership idiom; never manually manage a lifecycle the framework owns (see the stack's ORM/framework module)

**Security** (check each):
- [ ] Every SQL query uses bind parameters (`?` or `:named`)
- [ ] Every template/view output goes through the stack's context-aware encoding idiom
- [ ] Every endpoint has explicit access control check
- [ ] No hardcoded credentials, API keys, or secrets

**Performance** (check each):
- [ ] No SQL inside a loop (N+1)
- [ ] No `SELECT *` — columns listed explicitly
- [ ] WHERE/JOIN columns have indexes
- [ ] Result sets bounded (LIMIT or pagination)

**Convention** (check each):
- [ ] Language level matches the declared stack — expand the agent floor's banned symbols and grep the diff; zero hits
- [ ] Persistence and transaction idioms match the floor and stack modules — no ORM or transaction pattern the floor bans (module-sanctioned carve-outs allowed)
- [ ] Logging uses the stack's parameterized-logging idiom — no string concatenation in log calls
- [ ] No speculative abstraction or unrequested flexibility — minimum code for the asked change (YAGNI)

**Build Manifest / Dependencies** (check if the build manifest is in scope):
- [ ] No snapshot or floating version markers in release builds — every dependency and plugin pinned
- [ ] Versions centralized per the stack's config module — no per-module duplicates
- [ ] Test-only libraries scoped to test; container-provided APIs scoped as provided (or the stack's equivalent)
- [ ] Dependencies not on known-CVE versions — EOL versions pinned by the declared stack are documented baseline risk per the stack's security module, not a per-PR finding
- [ ] Compiler source/target matches the declared language level; all plugin versions pinned

## Phase 3 — Classify Findings

| Severity | Definition | Action |
|---|---|---|
| 🔴 CRITICAL | Security vuln, data loss, crash | Must fix before merge |
| 🟠 HIGH | Bug, perf issue, convention violation | Should fix |
| 🟡 MEDIUM | Style, naming, minor improvement | Nice to fix |
| ⚪ LOW | Preference, trivial | Optional |

## Phase 4 — Require Build & Test Evidence

The reviewer is read-only and does not run the build itself — require the author to supply it.

Before rendering a verdict, confirm fresh evidence that the change builds and tests pass:

- [ ] Actual build/test runner output is present in the PR / change context (a clean build-and-test run, or at least compile + test)
- [ ] The evidence reflects the **current** revision under review — not a stale run from before the latest change
- [ ] Tests covering the change actually ran (not skipped via runner flags)

If build/test evidence is missing or stale, you **cannot** APPROVE — render REQUEST CHANGES (or NEEDS DISCUSSION) and ask the author to attach fresh build/test output. Never infer a passing build from reading the diff.

## Phase 5 — Render Verdict

Classify all findings, then format using the Output Template below.

APPROVE requires ALL of:

- Zero unresolved 🔴 CRITICAL or 🟠 HIGH findings
- Fresh build & test evidence for the current revision (Phase 4)
- No outstanding floor, convention, or N+1 violations from Phase 2

Otherwise render REQUEST CHANGES or NEEDS DISCUSSION.

## Output Template

Per finding: `[SEVERITY] Category — description @ file:line → suggestion`

```
## Verdict: APPROVE / REQUEST CHANGES / NEEDS DISCUSSION
Findings: N critical, N high, N medium, N low
Evidence: <build/test command + result, or "MISSING — fresh build/test output required">
Summary: <one-sentence assessment>
```

## Handoffs

- → `@implementer` — to fix findings
- → `debug` skill — when a finding needs root-cause analysis
- → `security-audit` skill — security concerns warrant deeper audit
- → `sql-review` skill — SQL issues or migration / DDL changes warrant dedicated review
