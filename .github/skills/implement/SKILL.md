---
name: implement
description: 'Use when user asks to implement a feature, write new code, add functionality, or build something. Also triggers on: 幫我寫, 實作這個功能, 開發, 新增功能, 加一個 API, 寫一個 method. Guides implementation through pattern discovery, coding, and self-verification. Do NOT use for bug fixes (prefer debug), code cleanup (prefer refactor), or reviewing existing code (prefer code-review).'
---

# Implement — Executable Workflow

Defines the implementation PROCESS only. Coding standards (naming, error handling, logging, security) live in `copilot-instructions.md` and `instructions/` — do not restate here.

## Phase 1 — Understand Before Writing

**Clarify requirements** — confirm inputs/outputs, success criteria, edge cases, and what existing functionality this interacts with. If anything is ambiguous, **ask — do not assume**.

**Locate related code**:

```bash
find . -name "*.java" | head -30                                          # similar responsibility
grep -r "related keyword" --include="*.java" -l                           # related patterns
grep -rn "interface\|abstract class" --include="*.java" | grep -i "term"  # contracts to implement
```

**Identify patterns to follow** — a similar existing class, target package/dir, naming conventions, dependency-injection style, and error-handling style of the surrounding layer. Match them exactly before writing.

## Phase 2 — Implement

Write in this order to minimize back-and-forth: **Data/Model → Interface/Contract → Core logic → Integration → Error paths** (boundaries only — trust internal calls).

Keep it minimal: solve only what was asked, match surrounding complexity, reuse helpers, no abstractions for hypothetical futures (YAGNI).

## Phase 3 — Self-Verify

Before presenting, confirm:

- Compiles cleanly; imports resolved; no unused vars/imports
- Doesn't break existing callers; signatures match interfaces; shared config (pom.xml, properties) remains backward compatible
- Happy path correct; null/empty/boundary inputs behave reasonably; error messages debug-friendly

## Phase 4 — Present

Report **What** + **Where** (file paths) + **Pattern followed** (reference class) + **Key decisions (why)** + **Not included (why)**. Suggest next: `@test-designer` / `@reviewer` / `@sql-expert` / `@security` as applicable.
