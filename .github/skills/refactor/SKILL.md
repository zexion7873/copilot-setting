---
name: refactor
description: 'Use when user asks to refactor, clean up, simplify, or restructure code without changing behavior. Triggers on: refactor, clean up, simplify, restructure, extract method, rename, eliminate code smell, decompose, 重構, 整理一下, 這段太亂了, 簡化, 拆開這個 method, 抽出方法, 重新命名. Covers extract method, rename, decompose large functions, and eliminate code smells. Do NOT use for bug fixes (prefer debug), writing new features or adding new endpoints (prefer implement), formatting-only changes, or when the goal is to review rather than modify (prefer code-review).'
---

# Refactor — Workflow

Improve structure without changing external behavior. Refactoring is evolution, not rewrite.

Full coding standards live in `instructions/*.instructions.md` (auto-applied when matching files are open). When working via agent chat, these non-negotiable rules still apply:

- **SQL**: never regress `PreparedStatement` to string concatenation during restructuring
- **Exceptions**: no empty `catch` blocks; maintain layer-boundary translation when extracting methods
- **Logging**: keep SLF4J parameterized — `log.info("x={}", x)` — never introduce `+` concatenation
- **Resources**: preserve `try-with-resources` for all `AutoCloseable` — critical when extracting methods that handle `Connection`, `PreparedStatement`, `ResultSet`
- **Security**: no hardcoded secrets; maintain input validation at boundaries; keep `<c:out>` in JSP

## Rules

1. **Behavior preserved** — change how, not what
2. **Small steps** — tiny change, run tests, commit, repeat
3. **Tests are the safety net** — without them you are not refactoring, you are editing
4. **One thing at a time** — never mix refactor with feature change
5. **Commit often** — every passing state is a checkpoint

## When NOT to Refactor

- Code works and won't change again
- Critical production code without tests → write the tests first
- Tight deadline → defer
- "Just because" → need a real purpose

## Code Smells & Fixes

| Smell | Symptom | Fix |
|---|---|---|
| Long Method | 100+ lines, multiple responsibilities | Extract Method per cohesive block |
| Duplicated Code | Same logic in N places | Extract function or shared helper |
| Large Class (God Object) | 20+ methods covering unrelated concerns | Split by responsibility |
| Long Parameter List | 5+ params | Introduce Parameter Object / Builder |
| Feature Envy | Method uses another object's data more than its own | Move method to the data's owner |
| Primitive Obsession | Strings / ints for domain concepts | Wrap in domain types (`Email`, `Money`) |
| Magic Numbers / Strings | Unexplained literals | Named constants / enums |
| Nested Conditionals | 4+ levels of if | Guard clauses / early returns |
| Dead Code | Unused functions, vars, commented-out blocks | Delete; git remembers |
| Inappropriate Intimacy | One class reaches deep into another | Tell-don't-ask: expose behavior, not state |

## Common Operations Reference

| Operation | When to use |
|---|---|
| Extract Method | A code block has a single purpose worth naming |
| Extract Class | Multiple methods share state unrelated to the rest |
| Inline Method / Class | The abstraction adds no value |
| Rename | Current name lies or is too vague |
| Introduce Parameter Object | Same 3+ params travel together |
| Replace Conditional with Polymorphism | `if (type == X)` repeats in many places |
| Replace Magic Number with Constant | Same literal in 2+ places or unclear meaning |
| Decompose Conditional | Boolean expression takes 3+ seconds to read |
| Replace Nested Conditional with Guard Clauses | More than 2 levels of nesting |
| Replace Type Code with Class / Enum | Field is `int status` with documented values |
| Replace Inheritance with Delegation | Subclass uses only some parent behavior |

## Safe Refactoring Process

1. **Prepare**: tests cover the area (write them first if missing); commit current state; new branch
2. **Identify**: pick one smell; understand current behavior end-to-end; plan target structure
3. **Refactor in micro-steps**: one tiny change → run tests → commit if green → repeat
4. **Verify**: full test pass; manual smoke if UI; perf unchanged or better
5. **Clean up**: update affected comments / docs; final commit

## Checklist

- [ ] Functions under ~30 lines
- [ ] Each function does one thing
- [ ] No duplication
- [ ] Names describe intent, not implementation
- [ ] No magic numbers / strings
- [ ] Dead code removed
- [ ] Related code colocated; module boundaries clear
- [ ] Dependencies flow one direction; no cycles
- [ ] Tests still cover the refactored code
- [ ] All tests pass

## Anti-Patterns

- Refactoring without tests → not refactoring, editing
- Mixing feature + refactor in one commit → reviewer can't tell what's safe
- Big-bang rewrite labeled "refactor" → that's a rewrite; price it as such
- Refactoring untouched code "while I'm here" → scope creep; separate task
- Adding abstractions for hypothetical needs → YAGNI; refactor to a real need

## Multi-File Refactor

When a refactor spans more than one file, write a plan **before** touching code. Use the `plan` skill for the full template.

### Sequencing Rule

1. **Interfaces / abstract types first** — establish the new contract
2. **Implementations** — adapt one at a time
3. **Call sites** — migrate consumers
4. **Tests** — update to match new shape
5. **Cleanup** — delete deprecated code, update docs

### Rules

- Each phase ends in a green build — never leave the tree broken between phases
- One commit per phase for clean rollback
- Verification step is **mandatory** between phases

## Reference Examples

Concrete before / after Java examples for common refactorings:

- `examples/extract-method.md` — Extract Method with thresholds (LOC > 15, NOM > 10, CC > 10)
- `examples/remove-parameter.md` — Remove Parameter (unused / redundant params)
