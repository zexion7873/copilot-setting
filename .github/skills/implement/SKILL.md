---
name: implement
description: 'Use when user asks to implement a feature, write new code, add functionality, or build something. Also triggers on: 幫我寫, 實作這個功能, 開發, 新增功能, 加一個 API, 寫一個 method. Guides implementation through pattern discovery, coding, and self-verification. Do NOT use for bug fixes (prefer debug), code cleanup (prefer refactor), or reviewing existing code (prefer code-review).'
---

# Implement — Executable Workflow

## Overview

A lightweight implementation workflow that ensures new code aligns with existing patterns before writing. This skill defines the PROCESS, not coding standards (those live in copilot-instructions.md and instructions/).

## When to Use

- Implementing a new feature or user story
- Adding a new API endpoint, service method, or utility
- Writing a new class or module from scratch
- User asks "implement this", "write a method that...", "add a feature for..."

---

## Phase 1 — Understand Before Writing

Before writing any code, gather context.

### 1.1 Clarify Requirements

```
□ What is the expected input and output?
□ What are the success criteria?
□ Are there edge cases or constraints mentioned?
□ What existing functionality does this interact with?
```

If requirements are ambiguous, ASK — do not assume.

### 1.2 Locate Related Code

```bash
# Find files with similar responsibility
find . -name "*.java" | head -30

# Search for related patterns
grep -r "related keyword" --include="*.java" -l

# Check existing interfaces or abstract classes to implement
grep -rn "interface\|abstract class" --include="*.java" | grep -i "relevant term"
```

### 1.3 Identify Patterns to Follow

Before writing, answer:

```
□ Is there an existing class doing something similar? → Follow its structure
□ What package/directory should this live in? → Match the project's organization
□ What naming conventions are used? → Match them exactly
□ How are dependencies injected? → Constructor? Factory? Static?
□ How is error handling done in this layer? → Checked exceptions? Return codes?
```

---

## Phase 2 — Implement

### 2.1 Implementation Order

Write code in this order to minimize back-and-forth:

1. **Data/Model layer** — POJOs, entities, DTOs
2. **Interface/Contract** — Define the public API (interface or method signature)
3. **Core logic** — Business rules, algorithms
4. **Integration** — Wire into existing code (call sites, configuration)
5. **Error paths** — Handle failures at system boundaries only

### 2.2 Coding Checklist

```
□ Type hints on all method signatures
□ Follows existing naming conventions in the codebase
□ No new dependencies unless strictly necessary
□ Error handling at system boundaries (user input, external APIs, I/O)
□ Logging at appropriate level (not too verbose, not silent)
□ No hardcoded values — use constants or configuration
```

### 2.3 Keep It Minimal

```
DO:
  - Solve the stated problem
  - Match the complexity level of surrounding code
  - Reuse existing utilities and helpers

DO NOT:
  - Add features not requested
  - Build abstractions for hypothetical future needs
  - Add defensive code for impossible internal states
  - Create helper classes for one-time use
```

---

## Phase 3 — Self-Verify

After writing, verify before presenting.

### 3.1 Compilation Check

```
□ Does it compile without errors?
□ Are all imports resolved?
□ No unused variables or imports?
```

### 3.2 Integration Check

```
□ Does it break any existing callers?
□ Are method signatures compatible with interfaces/abstract classes?
□ If modifying shared config (pom.xml, properties), is it backward compatible?
```

### 3.3 Behavioral Check

```
□ Does the happy path produce correct output?
□ Do edge cases (null, empty, boundary values) behave reasonably?
□ Are error messages clear enough to debug in production?
```

---

## Phase 4 — Present the Result

### 4.1 Summary Format

```
## Implementation Summary

**What**: [One sentence — what was implemented]
**Where**: [File paths of new/modified files]
**Pattern followed**: [Which existing class/pattern was used as reference]

### Key Decisions
- [Decision 1 and why]
- [Decision 2 and why]

### Not Included (intentionally)
- [Anything deliberately left out and why]
```

### 4.2 Suggest Next Steps

```
□ Tests needed? → Suggest @test-designer or /test-design
□ Review needed? → Suggest @reviewer or /code-review
□ SQL involved? → Suggest @sql-expert or /sql-review
□ Security-sensitive? → Suggest @security or /security-audit
```

---

## Anti-Patterns

| Anti-Pattern | What to Do Instead |
|-------------|-------------------|
| Writing code without checking existing patterns | Always Phase 1.3 first |
| Over-engineering for future requirements | Solve today's problem only |
| Copy-pasting without understanding | Read the pattern, then write fresh |
| Ignoring error handling at boundaries | Validate external input, trust internal calls |
| Adding comments explaining WHAT | Let code be self-explanatory; comment only WHY |
