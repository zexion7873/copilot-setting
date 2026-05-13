---
name: adr
description: 'Use when user asks to record an architectural decision, document a tech choice, or write an ADR. Triggers on: record architectural decision, document tech choice, write ADR, capture decision rationale, ADR, 寫 ADR, 記錄架構決策, 紀錄技術選型, 為什麼選這個方案要存檔, 留個決策紀錄, 架構決策紀錄. Produces an ADR markdown file under /docs/adr/ using the standardized template (Status, Context, Decision, Consequences, Alternatives). Do NOT use for implementation plans (prefer plan skill), spikes / open research (prefer spike skill), or general design discussion without a final decision.'
---

# ADR — Workflow

Create an Architectural Decision Record. ADRs capture **a decision already made** (or being formalized) — not exploration. If the decision is still open, use `spike` instead.

## Phase 1 — Collect Inputs

Required before drafting:

- **Decision title** — short noun phrase (e.g. "Adopt PostgreSQL for OLTP")
- **Context** — problem statement, constraints, business / technical drivers
- **Decision** — the chosen solution
- **Alternatives** — at least one rejected option with rationale
- **Stakeholders** — names / roles approving the decision
- **Status** — Proposed / Accepted / Rejected / Superseded / Deprecated

If any are missing, ask the user — do not invent.

## Phase 2 — Locate the ADR Folder

```bash
ls docs/adr/ 2>/dev/null || mkdir -p docs/adr
ls docs/adr/ | grep -E '^adr-[0-9]{4}'  # find next sequential number
```

Filename: `adr-NNNN-[title-slug].md` (4-digit zero-padded sequence).

## Phase 3 — Draft Using Template

Use the template in `prompts/adr-template.prompt.md`. All coded identifiers (`POS-`, `NEG-`, `ALT-`, `IMP-`, `REF-`) must be used for cross-reference.

## Rules

- Coded bullets (`POS-NNN`, `NEG-NNN`, `ALT-NNN`, `IMP-NNN`, `REF-NNN`) — enables cross-reference
- Every alternative must include a rejection reason
- Both positive AND negative consequences — a decision with no downside is suspect
- No placeholder text in the final file — every field populated
- Status starts at `Proposed`; the user updates after review

## Handoffs

- → `plan` skill — if the decision needs an implementation plan
- → `spike` skill — if a sub-question still needs research
