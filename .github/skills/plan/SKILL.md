---
name: plan
description: 'Use when user needs a phased implementation plan with requirements, file impact, risks, and alternatives before coding — including clarifying vague or ambiguous requirements first. Triggers on: plan, design approach, implementation strategy, how should we build, clarify, unclear requirements, 規劃, 怎麼做, 幫我想方案, 寫計畫, 設計實作步驟, 先釐清, 需求不清楚. Produces a structured plan document, preceded by numbered clarifying questions when requirements have gaps. Do NOT use for atomic task lists (prefer tasks) or direct implementation of well-understood small tasks (prefer implement).'
---

# Plan — Workflow

Structured implementation plan. Clarify vague requirements first (Phase 1), then plan.

## Phase 1 — Clarify Requirements

Skip this phase when the request is already well-defined. When it is vague, ambiguous, or missing critical information:

1. **Parse the request** — extract goal (may be implicit), scope (modules/files/features involved), constraints (deadlines, tech limitations, backward compatibility)
2. **Identify gaps** — flag anything that would force guessing during implementation: missing acceptance criteria, ambiguous scope boundaries, unstated assumptions about existing behavior, conflicting requirements
3. **Ask numbered questions** — 3–7 questions; each states what is unclear, offers 2–3 concrete options when possible, and marks a recommended default if one exists. Do NOT ask questions the codebase can answer — scan first, ask only what code cannot tell you.
4. **Confirm understanding** — after answers, record the confirmed scope before planning:

```
## Confirmed Understanding
- Goal: ...
- Scope: ...
- Constraints: ...
- Out of scope: ...
- Open items: ... (if any remain)
```

## Phase 2 — Gather Context

1. Scan codebase for existing patterns relevant to the goal
2. Identify affected files and modules
3. Note constraints: tech stack (Java 8 / Maven / Spring 3.2 / Hibernate 4.2), backward compatibility, data migration needs

## Phase 3 — Classify Scope

| Scope | Definition | Plan depth |
|---|---|---|
| Small | 1–3 files, single module | Lightweight: goal + approach + files (template sections 1–3) |
| Medium | 4–10 files, cross-module | Standard: full template |
| Large | 10+ files, schema change, or API change | Full template + mandatory red-team depth (≥2 ASM/GAP entries) + migration/rollback plan (dedicated phases in section 2, RISK entries in section 5) |

## Phase 4 — Draft Plan

Fill the template below (Small scope: sections 1–3 only; Medium+: full template). Every section must be concrete:
- Requirements: traceable `REQ-NNN` / `CON-NNN` identifiers
- Approach: phased, each phase has a measurable goal
- Files: real paths from the codebase scan
- Risks: with specific mitigation, not generic "might be hard"
- Acceptance Criteria: verifiable `AC-NNN` outcomes — always fill (even Small scope); each must be testable, not aspirational

## Phase 5 — Validate

- [ ] Every phase has one clear goal
- [ ] File list matches codebase scan results
- [ ] No `TBD` or placeholders left
- [ ] Medium+ scope: Alternatives section has at least one rejected option with reason
- [ ] Refactor / structural plans: affected callers inventoried (verified via `find-impact`, not a single summary; Small plans record the inventory in the approach notes)
- [ ] Acceptance Criteria present and every `AC-NNN` is verifiable — a testable outcome, no aspirational wording ("fast", "user-friendly")

## Phase 6 — Red-Team the Plan

Before handing off, challenge the plan as an adversary would. Do not skip this when the plan "looks complete" — that is exactly when blind spots hide.

- **Unstated assumptions**: what must be true for this plan to work that you never wrote down? (data shape, library version, call order, single-threaded access…)
- **What breaks**: which existing caller, Spring bean, or `hbm.xml` mapping fails if you ship this as written?
- **Missing cases**: null/empty, concurrent access, stale cache after a write (which caches hold this data, who invalidates them, in what order relative to the DB write), rollback path, backward compatibility, migration ordering
- **Weakest link**: the one step you are least sure about — name it explicitly

Fold material findings back into sections 4–5 and record the residual assumptions and gaps in section 7 (Medium+ scope); for Small plans, append findings to the approach notes.

## Output Template

Write the plan to `docs/plans/<feature>/plan.md` — one folder per feature/change (create the folder if absent). The `tasks` skill writes `task.md` beside it in the same folder; keep this layout stable so the `source:` link resolves. Versioning is git history, not a `-vN` suffix.

```md
---
goal: <Concise plan title>
date: <YYYY-MM-DD>
owner: <owner>
status: 'Planned'
---

# <goal>

## 1. Requirements & Constraints

- REQ-001: <functional requirement>
- CON-001: <constraint — e.g., Java 8, no Spring Boot>
- PAT-001: <existing pattern to follow>

### Acceptance Criteria

Verifiable done conditions for the whole change — each must be testable, not aspirational ("fast" → "responds within 2s for 1000 rows"). Always fill, even for Small scope.

- [ ] AC-001: <observable, testable outcome>
- [ ] AC-002: <observable, testable outcome>

## 2. Implementation Approach

### Phase 1 — <Goal>

- What this phase achieves
- Approach: components touched, order of work

### Phase 2 — <Goal>

- ...

## 3. Files

- FILE-001: `path/to/File.java` — what changes

## 4. Impact / Affected Callers

- Refactors / structural changes: inventory every caller and dependent of changed symbols, across packages — verify with the `find-impact` prompt, do not rely on a single research summary
- IMP-001: `path/to/Caller.java:NN` — calls `<symbol>`; needs `<update>`
- Spring XML beans / `hbm.xml` mappings referencing changed types

## 5. Risks & Alternatives

- RISK-001: <risk> — mitigation: <specific action>
- ALT-001: <alternative considered> — rejected because <reason>

## 6. Dependencies

- DEP-001: <external or internal dependency>

## 7. Red-Team Notes

- ASM-001: <unstated assumption that must hold for this plan>
- GAP-001: <known gap / weakest link — what could break, and how it would be caught>
```

## Handoffs

- → `tasks` skill — to break plan into atomic task list
- → `implement` skill — when clarification resolves the task to a small, fully understood change that needs no plan
