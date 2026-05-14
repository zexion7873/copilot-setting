---
name: context-discovery
description: 'Use before implementing changes when the affected files / dependencies / tests are not yet identified. Triggers on: 動手前先盤點, 影響範圍, 哪些檔案會被改到, context map, 盤點一下, 我要先看哪些檔案. Produces a context map of files-to-modify, dependencies, tests, and reference patterns. Do NOT use for trivial single-file edits, when the user has already supplied the file list, or when the user asks to review or read existing code (prefer code-review skill).'
---

# Context Discovery — Workflow

Map the blast radius before touching anything. This skill prevents two failure modes: (a) editing without seeing related code, and (b) answering questions on incomplete information.

## Phase 1 — Decide the Mode

| Mode | When | Output |
|---|---|---|
| **Question mode** | User asked something; you need files to answer accurately | List of files needed |
| **Change mode** | User wants to modify code; you need to scope the change | Full context map |

If unclear, ask once: "Are you asking about the code, or asking me to change it?"

## Phase 2 — Question Mode (pre-answer)

Before answering, output the files-needed list. **Do not answer the question yet** — get the files first.

```bash
grep -rn "<key symbol from question>" --include="*.java" src/
find . -name "<plausible filename>" -not -path "*/target/*"
```

Output format:

```markdown
## Files I Need

### Must See (required for accurate answer)
- `src/main/java/com/example/MyService.java` — [why needed]

### Should See (helpful for complete answer)
- `src/main/java/com/example/MyDao.java` — [why helpful]

### Already Have
- `pom.xml` — [from earlier in conversation]

### Uncertainties
- [What I'm not sure about without seeing the code]
```

After the user supplies / approves, re-pose the question and answer it.

## Phase 3 — Change Mode (pre-implementation)

Build the full map. Don't skip this for "small" changes — the files you forget are the ones that break.

```bash
# direct usages
grep -rn "<symbol>" --include="*.java" src/
# tests touching the symbol
grep -rn "<symbol>" --include="*Test.java" --include="*IT.java" src/test/
# similar patterns to imitate
grep -rn "<related concept>" --include="*.java" src/
# DB / config touchpoints
grep -rn "<symbol>" --include="*.xml" --include="*.sql" --include="*.properties"
```

Output format:

```markdown
## Context Map

### Files to Modify
| File | Purpose | Changes Needed |
|---|---|---|
| src/main/java/com/example/MyService.java | service layer | add findActiveById |

### Dependencies (may need updates)
| File | Relationship |
|---|---|
| src/main/java/com/example/MyDao.java | called by modified file |
| src/main/resources/sql/myservice.xml | SQL for new method |

### Test Files
| Test | Coverage |
|---|---|
| src/test/java/com/example/MyServiceTest.java | tests affected functionality |

### Reference Patterns
| File | Pattern |
|---|---|
| src/main/java/com/example/SimilarService.java | example to follow |

### Risk Assessment
- [ ] Breaking changes to public API
- [ ] Database migrations needed
- [ ] Configuration changes required
- [ ] Cross-module callers affected
```

Do not proceed with implementation until the user reviews / approves the map.

## Rules

- Cite real files only — no invented paths
- Note uncertainties explicitly; do not silently guess
- "Already Have" entries reduce token waste — list them honestly
- When the map is huge (>15 files), surface that fact — the task may need splitting first

## Handoffs

- → `clarify-task` skill — if the map exposes ambiguity in the request
- → `plan` skill — if the change spans multiple phases
- → `implement` / `refactor` skill — once the map is approved
