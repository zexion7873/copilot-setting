---
source: ./plan.md
date: 2026-08-02
---

# Task Breakdown

## Tasks

| ID | Task | Size | Depends On | Markers | Done When |
|---|---|---|---|---|---|
| T001 | STYLE-GUIDE: generic Phase 0 skeleton, rules 3/4, cross-ref glob note, floor-map sentinel row, stack-swap lifecycle checklist | M | — | | Skeleton shows module-pointer Phase 0; sentinel row present |
| T002 | Agents ×3: drift-sentinel floor bullet (byte-identical), floor intro + pre-load constraint repointed at stack modules | S | T001 | | Validator floor + canary checks pass |
| T003 | Skills: plan — de-stack 4 touchpoints (Phase 2, Phase 6, CON-001 example, section 4) | S | T001 | [P] | AC-001 grep clean for plan |
| T004 | Skills: debug + refactor — swap Phase 0 body to generic gate | S | T001 | [P] | AC-001 grep clean for both |
| T005 | Skills: implement — description, opening, Phase 0, Phase 2 patterns, Phase 4 floor-grep indirection | M | T001 | [P] | AC-001 grep clean; floor-grep item present |
| T006 | Skills: verify — opening, Phase 0 (testing-module emphasis), Phase 2 runner-agnostic commands | S | T001 | [P] | AC-001 grep clean |
| T007 | Skills: code-review — Phase 0, category checklists via floor/module indirection, build-manifest section, Phase 4/5 runner-agnostic | M | T001 | [P] | AC-001 grep clean; evidence rule intact |
| T008 | Skills: security-audit — Phase 0, OWASP items via module indirection, A06 scan-tool wording, summary line | M | T001 | [P] | AC-001 grep clean; OWASP skeleton intact |
| T009 | Skills: sql-review — Phase 0, Phases 4–6 engine-agnostic with DDL-module pointers | M | T001 | [P] | AC-001 grep clean; both tracks intact |
| T010 | Prompts: check-n-plus-1 + find-impact de-ORM | S | T001 | [P] | AC-004 |
| T011 | Run validator + both regression suites + AC greps | S | T002–T010 | | AC-001/002/003/004/006 all green |
| T012 | AGENTS.md: two-layer architecture, loading-model wording | M | T011 | | Describes core/stack split accurately |
| T013 | README.md re-pitch + porting guide; README.zh-TW.md mirrored | L | T012 | | AC-005 |
| T014 | Memory notes updated (architecture decision, floor sentinel, module indirection) | S | T013 | | Memory files written |

### Markers

- `[P]` — parallel-safe at same dependency level
- `[US]` — requires user sign-off

## Dependency Graph

T001 → T002 → T011 → T012 → T013 → T014
T001 → T003..T010 ──┘

## Coverage Matrix

| Plan item | Tasks |
|---|---|
| REQ-001 / AC-001 | T003–T009 |
| REQ-002 / AC-002 | T002 |
| REQ-003 | T005, T007 |
| REQ-004 / AC-003 | (no-op — verified by T011) |
| AC-004 | T010 |
| AC-005 | T013 |
| AC-006 / CON-003 | T011 |
| CON-002 | T001 (STYLE-GUIDE first), single PR |
