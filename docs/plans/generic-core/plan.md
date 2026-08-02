---
goal: Split the config into a generic process core and a swappable stack layer
date: 2026-08-02
owner: Kevin Lin
status: 'In progress'
---

# Split the config into a generic process core and a swappable stack layer

## 1. Requirements & Constraints

- REQ-001: Skills and generic prompts must contain no hardcoded stack names, framework versions, or stack-specific file paths — portable to any stack layer unchanged.
- REQ-002: The version lock stays deterministic: the agent `## Coding Standards` floor remains the delivery channel, extended with a `pom.xml` drift sentinel.
- REQ-003: Skills enforce stack rules through indirection — "expand the floor's banned symbols and grep" / "open the stack modules under `instructions/`" — never by naming per-stack files.
- REQ-004: `instructions/` files and `copilot-instructions.md` are re-designated as the swappable stack layer with zero content changes.
- CON-001: Custom agents stay; no agent is deleted. Handoffs, model pinning, and the read-only reviewer are unchanged.
- CON-002: One atomic PR (repo lean-and-stable rule); STYLE-GUIDE updated first per its own protocol.
- CON-003: Validator and its regression suite must pass with zero script changes (the floor↔instruction canary keeps its home because instructions are unchanged).
- PAT-001: Phase 0 pre-load gate + read-back receipt pattern is preserved; only its body goes generic.

### Acceptance Criteria

- [ ] AC-001: `grep -rniE 'java|spring|hibernate|jsp|jstl|maven|mysql|junit|mockito|servlet|slf4j|c:out|transactional|tx:advice|hbm|mvn|pom\.xml|hql|jdbc' .github/skills/` returns zero hits.
- [ ] AC-002: Floor bullets are byte-identical across implementer/reviewer/debugger and include the drift sentinel; `validate-style-guide.sh` passes.
- [ ] AC-003: `git diff` for `.github/instructions/` and `.github/copilot-instructions.md` is empty.
- [ ] AC-004: `git-commit`, `check-tx`, `generate-migration-sql` prompts are byte-unchanged; `check-n-plus-1` and `find-impact` contain no ORM/framework-specific tokens.
- [ ] AC-005: README.md and README.zh-TW.md are section-by-section in sync and both describe the core/stack-layer split plus a porting guide.
- [ ] AC-006: `validate-style-guide.sh`, `test-validate-style-guide.sh`, and `test-block-dangerous-commands.sh` all pass with zero changes to the three scripts.

## 2. Implementation Approach

### Phase 1 — STYLE-GUIDE first

Update the skill skeleton's Phase 0 to the generic module-pointer form, the floor spec (drift sentinel row in the Floor ↔ Instruction map), the cross-reference guidance (no hardcoded instruction filenames in skills), and add a stack-layer swap checklist to File Lifecycle.

### Phase 2 — Agents (floor upgrade)

Add the drift-sentinel bullet to the floor (byte-identical ×3) and repoint the floor intro + Instruction pre-load constraint at "the stack modules under `instructions/`". planner/researcher untouched.

### Phase 3 — Skills genericization

Swap every Phase 0 body to the generic gate; replace stack-specific check items with floor-indirection or module-role phrasing per file (see tasks.md). `tasks` skill needs zero changes.

### Phase 4 — Generic prompts

De-ORM `check-n-plus-1` and `find-impact`. Other three prompts untouched.

### Phase 5 — Verify

Run the validator, its regression suite, and the hook regression suite; run the AC greps.

### Phase 6 — Docs

AGENTS.md: two-layer architecture + updated loading-model wording. READMEs: re-pitch around "generic process core + swappable stack layer (shipped with a Java 8 legacy reference stack)" + new porting section; zh-TW mirrored section by section.

## 3. Files

- FILE-001: `.github/STYLE-GUIDE.md` — skeletons, rules 3/4, cross-ref table, floor map, lifecycle
- FILE-002: `.github/agents/{implementer,reviewer,debugger}.agent.md` — floor sentinel + module-pointer prose
- FILE-003: `.github/skills/{plan,debug,refactor,implement,verify,code-review,security-audit,sql-review}/SKILL.md` — genericization
- FILE-004: `.github/prompts/{check-n-plus-1,find-impact}.prompt.md` — de-ORM
- FILE-005: `AGENTS.md`, `README.md`, `README.zh-TW.md` — architecture + pitch + porting guide

## 4. Impact / Affected Callers

- IMP-001: Downstream Copilot sessions — skill bodies change wording but keep every gate/receipt mechanism; floor gains one bullet.
- IMP-002: Validator xref count drops (skills no longer path-reference instructions) — allowed; no validator change.

## 5. Risks & Alternatives

- RISK-001: Genericized check items lose grep sharpness — mitigation: floor indirection keeps concrete symbols reachable ("expand the floor's banned symbols").
- RISK-002: zh-TW README drifts from English — mitigation: AC-005 section-by-section check.
- ALT-001: Full genericization incl. instructions — rejected: destroys the version-archaeology content the pack exists for.
- ALT-002: Dropping custom agents for the default agent — rejected: loses the only deterministic hard-rule channel, model pinning, and the read-only review pass.

## 6. Dependencies

- DEP-001: None external; validator + test scripts are the gate.

## 7. Red-Team Notes

- ASM-001: VS Code injects the selected agent's body every request — floor indirection only works because floor and skill share the context window.
- GAP-001: Porting to a new stack must update the canary anchor registry inside `validate-style-guide.sh` (anchors are stack tokens) — recorded in the README porting guide and STYLE-GUIDE lifecycle checklist.
