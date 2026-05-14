---
name: implement
description: 'Use when user asks to implement a feature, write new code, add functionality, or build something. Triggers on: implement, write new code, add functionality, build feature, create endpoint, add API, write method, code this up, 幫我寫, 實作這個功能, 實作, 開發, 新增功能, 加一個 API, 寫一個 method, 把它寫出來. Guides implementation through pattern discovery, coding, and self-verification. Do NOT use for bug fixes (prefer debug), restructuring or cleaning up existing code without adding new behavior (prefer refactor), or reviewing existing code (prefer code-review).'
---

# Implement — Executable Workflow

Defines the implementation PROCESS only. Full coding standards live in `copilot-instructions.md` and `instructions/` (auto-applied when matching files are open). When working via agent chat, these non-negotiable rules still apply:

- **SQL**: `PreparedStatement` with `?` only — never concatenate user input into SQL
- **Exceptions**: no empty `catch` blocks; translate at layer boundaries; never catch `Throwable`
- **Logging**: SLF4J parameterized — `log.info("x={}", x)` — never `+` concatenation or `e.printStackTrace()`
- **Resources**: `try-with-resources` for all `AutoCloseable` (`Connection`, `PreparedStatement`, `ResultSet`)
- **Security**: no hardcoded secrets; validate inputs at boundaries; output-encode in JSP

## Phase 1 — Understand Before Writing

**SDD-first gate (NON-NEGOTIABLE)** — Search the workspace for an SDD or plan document covering this task. Look in `docs/spec/`, `/plan/`, or any path the user mentioned. If one exists, read it completely — it defines scope, constraints, and acceptance criteria your implementation MUST satisfy. If none exists, evaluate the expected change scope BEFORE writing any code:

- Single-file / trivial change → proceed; note "no SDD: trivial scope" in the final report.
- Expected to touch 2+ production files (test files paired with their production counterpart do not count) OR introduces new public behavior (new API, new entity, new flow) → **STOP**. Ask the user:
  > No SDD found. This change is expected to touch 2+ production files or introduce new behavior. Choose one:
  > (a) Create an SDD first (recommended — use `sdd` skill or `@planner`)
  > (b) Proceed without SDD (will be noted as exception in implementation report)

Do NOT silently skip this gate. Silently skipping is the failure mode this rule exists to prevent.

**Clarify requirements** — confirm inputs/outputs, success criteria, edge cases, and what existing functionality this interacts with. If anything is ambiguous, **ask — do not assume**. Cross-check against the SDD if one exists.

**Locate related code**:

```bash
grep -rn "class.*ClassName\|interface.*Name" --include="*.java" src/      # similar responsibility
grep -r "related keyword" --include="*.java" -l src/                      # related patterns
grep -rn "interface\|abstract class" --include="*.java" src/ | grep -i "term"  # contracts to implement
```

**Identify patterns to follow** — a similar existing class, target package/dir, naming conventions, dependency-injection style, and error-handling style of the surrounding layer. Match them exactly before writing. If the implementation involves an unfamiliar library or API, use Context7 to fetch its docs before writing code.

## Phase 2 — Implement

Write in this order to minimize back-and-forth: **Data/Model → Interface/Contract → Core logic → Integration → Error paths** (boundaries only — trust internal calls).

Keep it minimal: solve only what was asked, match surrounding complexity, reuse helpers, no abstractions for hypothetical futures (YAGNI).

## Phase 3 — Self-Verify

Before presenting, confirm:

- Compiles cleanly; imports resolved; no unused vars/imports
- Doesn't break existing callers; signatures match interfaces; shared config (pom.xml, properties) remains backward compatible
- Happy path correct; null/empty/boundary inputs behave reasonably; error messages debug-friendly

## Phase 4 — Present

Report **What** + **Where** (file paths) + **Pattern followed** (reference class) + **Key decisions (why)** + **Not included (why)**. Suggest next: `@reviewer` for code / security / SQL review as applicable.
