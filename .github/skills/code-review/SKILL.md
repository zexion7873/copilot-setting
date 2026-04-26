---
name: code-review
description: 'Structured code review workflow for systematic, reproducible reviews. Use when reviewing a PR, a set of changes, or code against a plan. Walks through: scope identification, diff analysis, plan compliance check, issue classification, and final verdict. Designed for @reviewer agent but usable by any agent performing review.'
license: MIT
allowed-tools: ['search', 'read/problems']
---

# Code Review — Executable Workflow

## Overview

A step-by-step review process that turns ad-hoc code reading into a systematic, reproducible review. This skill defines HOW to review, not WHAT to check (that's in the agent prompt and instructions).

## When to Use

- Reviewing a PR or a set of commits
- Checking implementation against a plan (PLAN.md, ADR, ticket)
- Post-implementation self-review before merging
- User asks "review this", "check my changes", "is this ready to merge"

---

## Phase 1 — Scope the Review

Before reading any code, understand what you're reviewing.

### 1.1 Identify Changed Files

```bash
# If reviewing a branch against main
git diff --name-only main...HEAD

# If reviewing staged changes
git diff --staged --name-only

# If reviewing specific commits
git diff --name-only <commit1>..<commit2>

# Get a stat summary
git diff --stat main...HEAD
```

### 1.2 Classify the Change

Determine the nature of the change before diving in:

| Type | Review Focus |
|------|-------------|
| New feature | Does it meet requirements? Edge cases? Tests? |
| Bug fix | Does it fix the root cause? Regression risk? |
| Refactor | Behavior preserved? Tests still pass? |
| Config/infra | Security? Environment-specific issues? |
| SQL/migration | Reversibility? Performance? Data integrity? |

### 1.3 Check for a Plan

Look for an associated plan or specification:

```
Search for:
- .plans/*.md or PLAN.md in the project
- Referenced ticket/issue number in commit messages
- ADR (Architecture Decision Record) if architectural changes
```

If a plan exists, the review MUST check compliance against it.

---

## Phase 2 — Read the Diff

Read changes in a specific order to build understanding efficiently.

### 2.1 Reading Order

1. **Data layer first** — Models, entities, database migrations, SQL
2. **Business logic second** — Services, handlers, processors
3. **Interface layer third** — Controllers, APIs, CLI handlers
4. **Configuration** — Properties, XML configs, POM changes
5. **Tests last** — Verify they cover the changes above

### 2.2 Per-File Review

For each changed file, check:

```
□ Purpose — Why was this file changed? Does it make sense?
□ Scope — Does the change stay within the file's responsibility?
□ Side effects — Could this change break callers or dependents?
□ Completeness — Is anything missing (error handling, logging, validation)?
```

### 2.3 Cross-File Review

After individual files, check relationships:

```
□ Consistency — Do naming, patterns, and error handling match across files?
□ Dependencies — Are new dependencies necessary? Any circular references?
□ Transaction boundaries — Do multi-step operations have proper atomicity?
□ Thread safety — Are shared resources properly synchronized?
```

---

## Phase 3 — Plan Compliance (if applicable)

If a plan or specification exists:

### 3.1 Step-by-Step Verification

```
For each step in the plan:
  □ Is it implemented?
  □ Does the implementation match the plan's intent?
  □ Are there deviations? If so, are they justified?
```

### 3.2 Deviation Report

If deviations are found:

```
DEVIATION: [Plan step N]
  Plan said: [what the plan specified]
  Code does: [what was actually implemented]
  Impact: [Low/Medium/High]
  Justified: [Yes — reason / No — needs correction]
```

---

## Phase 4 — Issue Classification

Classify every finding using these severity levels.

### Severity Definitions

**🔴 CRITICAL — Must fix before merge**
- Security vulnerability (injection, auth bypass, secret exposure)
- Data corruption or loss risk
- Crash or unhandled exception in main path
- Breaking change without versioning

**🟡 WARNING — Should fix, discuss if blocked**
- Performance issue (N+1 queries, missing index, unnecessary allocation)
- Missing error handling in non-critical path
- Test coverage gap for changed code
- Deviation from established patterns without justification

**🔵 SUGGESTION — Non-blocking improvement**
- Naming could be clearer
- Code could be simplified
- Comment missing or outdated
- Minor style inconsistency

### Issue Format

```
[SEVERITY] Category — Brief title
  File: path/to/File.java#methodName (line N)
  Problem: What's wrong and why it matters
  Suggestion: How to fix it
  Code:
    // Before
    problematic code here

    // After
    suggested fix here
```

---

## Phase 5 — Final Verdict

### 5.1 Summary Table

```
| Severity    | Count |
|-------------|-------|
| 🔴 CRITICAL |   N   |
| 🟡 WARNING  |   N   |
| 🔵 SUGGESTION | N   |
```

### 5.2 Verdict

| Condition | Verdict |
|-----------|---------|
| 0 Critical, 0 Warning | ✅ **APPROVED** — Ready to merge |
| 0 Critical, 1+ Warning | ⚠️ **APPROVED WITH COMMENTS** — Merge after addressing warnings |
| 1+ Critical | ❌ **CHANGES REQUESTED** — Must fix before merge |

### 5.3 Verdict Statement

```
## Review Verdict: [APPROVED / APPROVED WITH COMMENTS / CHANGES REQUESTED]

**Scope**: [Brief description of what was reviewed]
**Plan compliance**: [Fully compliant / N deviations found / No plan referenced]

### What's Good
- [Positive observation 1]
- [Positive observation 2]

### Must Fix (if any)
1. [Critical issue summary — link to detail above]

### Should Fix (if any)
1. [Warning summary — link to detail above]

### Suggestions (if any)
1. [Suggestion summary]
```

---

## Review Anti-Patterns

Avoid these common review mistakes:

| Anti-Pattern | Why It's Bad |
|-------------|-------------|
| Rubber-stamp approval | Defeats the purpose of review |
| Style-only feedback | Misses real issues |
| Rewrite suggestions | Review scope creep — file a separate task |
| No positive feedback | Demoralizing, misses chance to reinforce good patterns |
| Reviewing without running | Missing runtime issues that static analysis catches |

---

## Quick Review Checklist

For smaller changes, use this condensed checklist:

```
□ Does it do what it's supposed to do?
□ Could it break anything else?
□ Are errors handled?
□ Are inputs validated?
□ Is there a test?
□ Would I understand this code in 6 months?
```
