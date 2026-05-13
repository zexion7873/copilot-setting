---
name: sdd-review
description: 'Use when user asks to review an SDD, audit a spec, or verify a specification document before implementation. Triggers on: review SDD, audit spec, check the spec, is this SDD ready, 審查 SDD, 檢查規格文件, 規格審查, 這份 SDD 可以嗎, 規格夠不夠完整. Evaluates SDD completeness, testability, feasibility, and clarity. Do NOT use for code review (prefer code-review skill), implementation plan review without spec depth (prefer plan skill), writing a new SDD (prefer sdd skill), or general documentation review.'
---

# SDD Review — Workflow

Structured review of a specification document before implementation begins. This skill evaluates completeness, testability, feasibility, and clarity. It does NOT rewrite the SDD — it returns a verdict with actionable findings.

## Phase 1 — Locate the SDD

Find the document to review:

- User provides a path directly — read it
- No path given — search for recent SDD files:

```bash
find . -name "*.md" -newer .git/index | head -20   # recently modified markdown
grep -rl "Acceptance Criteria\|Out of Scope" --include="*.md" .
```

Read the full document before proceeding. Do not skim.

## Phase 2 — Completeness Check

Verify all 8 required sections are present and populated. Placeholder text (`TBD`, `TODO`, `...`, empty sections) counts as missing.

| # | Section | Present? | Populated? |
|---|---------|----------|------------|
| 1 | Background & Objectives | | |
| 2 | Current State | | |
| 3 | Proposed Design (Architecture, API Spec, Schema, Business Rules) | | |
| 4 | Acceptance Criteria (numbered, testable) | | |
| 5 | Non-Functional Requirements | | |
| 6 | Dependencies & Risks | | |
| 7 | Files to Change (real paths) | | |
| 8 | Out of Scope | | |

Score: N/8 sections fully populated.

## Phase 3 — Quality Audit

For each populated section, evaluate across six dimensions:

| Dimension | Check |
|---|---|
| Testability | Every AC is binary pass/fail, no subjective language ("fast", "user-friendly", "reasonable") |
| Feasibility | File paths exist in the codebase, tech assumptions match the stack |
| Clarity | No ambiguous design decisions, no hand-waving ("handle appropriately", "as needed") |
| Completeness | No placeholder text, no TBD without explicit justification |
| Consistency | No contradictions between sections (e.g., API spec vs. schema, AC vs. scope) |
| Scope control | Out of Scope section present and specific enough to prevent creep |

Flag each failure with the section name and the exact text that triggered it.

## Phase 4 — Verdict

| Findings | Verdict |
|---|---|
| All sections complete, all checks pass | APPROVED — ready for implementation |
| Minor gaps (missing NFRs, vague risk mitigations) | APPROVED WITH COMMENTS — address before starting |
| Missing sections, untestable ACs, placeholder text | REVISIONS REQUIRED — send back to author |

Output format:

```
## SDD Review Verdict: <APPROVED / APPROVED WITH COMMENTS / REVISIONS REQUIRED>

Document: <path to SDD>
Author: <if known>

Completeness: N/8 sections fully populated
Testability: N/N acceptance criteria are binary pass/fail

Strengths:
- <positive observation>

Must fix:
1. <issue + specific fix>

Should fix:
1. <suggestion>
```

## Rules

- Review the SDD as-is — do not rewrite it during review
- Flag any AC that uses subjective language ("should be fast", "user-friendly", "acceptable performance")
- Verify file paths reference real files in the codebase; flag phantom paths as MUST FIX
- If schema changes lack a rollback strategy, flag as MUST FIX
- Cross-reference with any plan or ADR cited in the SDD — inconsistencies are findings
- At least one positive observation is required in the output

## Handoffs

- → `sdd` skill — if REVISIONS REQUIRED, author rewrites using the sdd skill
- → `@planner` — for major structural rewrites beyond targeted fixes
- → `implement` skill / `@implementer` — once verdict is APPROVED or APPROVED WITH COMMENTS
- ← `sdd` skill — SDD creation naturally leads to review
- ← `plan` skill — plans that became SDDs need review before implementation starts
