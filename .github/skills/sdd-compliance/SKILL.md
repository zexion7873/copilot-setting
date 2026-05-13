---
name: sdd-compliance
description: 'Use AFTER implementation to verify the code actually delivers what the spec promised. Triggers on: 驗收, spec 驗收, 規格對齊, 對得上 spec 嗎, 實作有照 spec 嗎, 驗證需求覆蓋, verify spec compliance, check implementation against spec, AC coverage check, acceptance verification, requirements traceability. Produces a compliance matrix mapping every FR / AC / SC to tasks, tests, and code evidence, with PASS / PARTIAL / FAIL verdict. Do NOT use for code style / bug review (prefer code-review skill), for spec quality review BEFORE implementation (prefer sdd-review skill), for SQL or security focused checks (prefer sql-review / security-audit), or when no spec / SDD exists (this skill needs a spec to compare against).'
---

# SDD Compliance — Workflow

Verify that implementation delivers what the spec specified. Strictly read-only review producing a structured compliance matrix. Does NOT rewrite code, does NOT run tests / builds, does NOT critique style. Boundary kept tight on purpose: style and bugs are `code-review`'s job; spec quality is `sdd-review`'s job; running tests is the user's job. This skill only checks the contract using artifacts already on disk.

## Phase 1 — Locate Artifacts

Required inputs:

- **Spec**: `/docs/spec/*.md` OR user-provided path — REQUIRED
- **Tasks**: `tasks.md` — preferred (provides task-to-AC mapping)
- **Implementation diff**: `git diff <base>...HEAD` or user-specified commit range — REQUIRED

If spec missing: STOP. Ask user for the SDD path. This skill cannot operate without a target to compare against.

If tasks.md missing: PROCEED but flag in verdict that traceability will be code-only.

## Phase 2 — Build Compliance Matrix

For each requirement row in the spec (`FR-`, `AC-`, `SC-`, `NFR-`, etc.):

| Spec ID | Statement | Task(s) | Test(s) | Evidence (file:line) | Status |

Status values:

- ✅ **COVERED** — task done, test exists and passes, behavior verifiable in code
- ⚠️ **PARTIAL** — task done but test missing OR test exists but fails OR evidence inconclusive
- ❌ **MISSING** — no task, no test, no code evidence
- 🚫 **ORPHANED** — implementation found that no spec entry maps to (flagged at end of matrix, not per row)

Use `git diff` and `git log` to find code evidence. Cite `path/to/File.java:42` format.

## Phase 3 — Test Evidence Collection (read-only)

Tests are the primary compliance signal. This phase is strictly read-only — it does NOT run tests, builds, or any other tooling. If evidence is absent, mark it absent.

1. **Read existing reports** — check `target/surefire-reports/*.xml` (Maven) or `target/site/jacoco/` for coverage data
2. **No report found** — mark affected ACs as `⚠️ PARTIAL` with reason `NO_TEST_EVIDENCE`. Note in the verdict that the user should run `mvn test` (or equivalent) and re-invoke this skill for a complete review.

Never assume tests pass without evidence. Never assume tests fail without evidence either. Never run tests yourself — that breaks the read-only contract.

## Phase 4 — Cross-Artifact Consistency

Inspired by Spec-Driven Development's cross-artifact analysis approach (see Spec Kit for prior art):

- **Spec ↔ Tasks** — every AC has ≥1 task in tasks.md; flag uncovered
- **Tasks ↔ Code** — every completed `[x]` task produced its expected file changes
- **Spec ↔ Constitution** — implementation respects non-negotiable principles (e.g., if constitution mandates TDD, every implementation task has a paired test task)
- **Out-of-Scope ↔ Diff** — code touching files outside SDD §7 is ORPHANED unless justified

## Phase 5 — Verdict

| Findings | Verdict |
|---|---|
| All ACs `✅ COVERED`, all tests pass | ✅ **COMPLIANT** |
| All ACs covered, some tests gap / missing reports | ⚠️ **COMPLIANT WITH GAPS** |
| 1+ AC `❌ MISSING` OR 1+ critical ORPHANED code | ❌ **NON-COMPLIANT** |

Final report skeleton:

```
## Compliance Verdict: <COMPLIANT / COMPLIANT WITH GAPS / NON-COMPLIANT>

Spec: <path>
Implementation scope: <diff range, e.g., main...HEAD>
Test evidence source: <surefire-reports / jacoco / NO_TEST_EVIDENCE — user should run tests and re-invoke>

Coverage: N/M ACs covered (X%)
Test traceability: N/M ACs have passing tests

## Compliance Matrix

| Spec ID | Statement | Tasks | Tests | Evidence | Status |
|---|---|---|---|---|---|
| AC-001 | ... | T010, T011 | OrderServiceTest#findByCustomerId | OrderService.java:42 | ✅ |
| AC-007 | ... | (none) | (none) | (none) | ❌ |

## Gaps

- AC-007: no task generated, no test, no code evidence — implementation missing
- AC-012: implementation in OrderService.java:88 diverges from SDD §3.2 (returns List, spec says Page)

## Orphaned implementation

- `src/main/java/.../UnusedHelper.java` — not traced to any spec ID, not declared in SDD §7

## Next actions

1. Implement AC-007 — hand off to @implementer with this matrix
2. Reconcile AC-012 — either fix code or amend SDD §3.2 (hand off to @planner)
3. Justify or remove UnusedHelper.java
```

## Rules

- This skill is **READ-ONLY**. Never edit code, never propose inline fixes (point to next skill instead).
- Every gap MUST cite a Spec ID and a concrete `file:line` OR `(none)` for missing evidence.
- Do NOT duplicate `code-review` work — style, naming, bug patterns are out of scope.
- Do NOT duplicate `sdd-review` work — spec quality is out of scope (assume spec is good; if it's not, hand back to `sdd-review`).
- Test evidence is read-only — if no test report exists, declare `NO_TEST_EVIDENCE` rather than running tests yourself. The user re-invokes this skill after generating reports.
- ORPHANED code is a finding, not a verdict-blocker — implementation can be COMPLIANT WITH GAPS even with orphans.

## Handoffs

- → `code-review` skill — for style / correctness issues found while reading code
- → `implement` skill / `@implementer` — to fix gaps
- → `sdd` skill / `@planner` — when spec turns out to be wrong rather than the code
- → `test-design` skill — when AC has no test and one needs designing
- ← `tasks` skill — tasks.md is the preferred input
- ← `implement` skill — implementation completion naturally triggers compliance check
