<!--
Sync Impact Report:
Version: 0.0.0 → 1.0.0 (initial)
Modified principles: N/A (new constitution)
Added sections: Core Principles, Governance
Removed sections: N/A
Templates requiring updates: N/A (no existing references)
Follow-up TODOs:
- Replace [Project Name] with the actual project name
- Customize Core Principles I-V to match your project's non-negotiables
- Set RATIFIED date when the team approves this constitution
-->

# [Project Name] Constitution

This is the project's stable, non-negotiable rules and governance. It supersedes other development practices when in conflict. File-type and language-specific conventions live in `.github/instructions/`; one-off decisions live in `docs/adr/`.

## Core Principles

### I. Test-Driven Development (NON-NEGOTIABLE)

Tests MUST be written before implementation for all new behavior. Red → Green → Refactor cycle is mandatory. Code merged without paired tests is rejected.

Rationale: AI-assisted implementation drifts without test gates. Tests are the executable spec.

### II. Spec Before Code

For any non-trivial feature, an SDD (Spec-Driven Development document) MUST exist and be reviewed before tasks are generated. Atomic task decomposition runs after SDD approval, not before.

Rationale: Vibe coding produces drift. Spec-driven flow keeps requirements traceable from idea to merge.

### III. Single Source of Truth Per Concern

Each rule lives in exactly one place. SQL rules in `sql-rules.instructions.md`, not duplicated across skills. Coding style in instructions, not in constitution. Constitution holds only project-wide non-negotiables.

Rationale: Duplication rots. One source means one place to fix when reality changes.

### IV. Read-Only Reviews

Review skills (`code-review`, `sdd-compliance`, `sdd-review`, `sql-review`, `security-audit`) MUST NOT edit code. They report findings; the implementation skill fixes them. Boundary kept tight.

Rationale: Mixing review and implementation makes diff archaeology painful and blurs accountability.

### V. Explicit Over Implicit

Variable names MUST describe intent. Magic numbers MUST be named constants. Public APIs MUST have Javadoc. WHY comments are valued; WHAT comments are noise.

Rationale: Code is read 10x more than written. Future readers — including AI — depend on explicit context.

## Governance

This constitution supersedes other development practices when in conflict.

Amendments require:

1. Documented rationale
2. Sync Impact Report prepended to this file (use the `constitution` skill)
3. Version bump per the rules below
4. PR review by at least one project maintainer

**Versioning**:

- **MAJOR**: principle removal or backward-incompatible rule change (e.g., dropping TDD requirement)
- **MINOR**: principle addition or materially expanded section (e.g., adding a "VI. Observability" principle)
- **PATCH**: wording, typo, clarification — no semantic change

All PRs MUST verify compliance with these principles. Complexity beyond these standards MUST be justified in the PR description or an ADR.

**Version**: 1.0.0 | **Ratified**: TBD | **Last Amended**: TBD
