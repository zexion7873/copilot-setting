---
name: spike
description: 'Use when user asks to research a technical question, evaluate options, build a PoC, or time-box an investigation. Triggers on: spike, research, time-boxed investigation, PoC, evaluate options, prototype, technical question, 技術調研, 評估方案, 試水溫, 做 PoC, 時間盒研究, 先研究一下, 試試看可不可行. Produces a time-boxed spike document under docs/spikes/ with one focused question, investigation plan, and decision section. Do NOT use for decisions already made (prefer adr skill), full implementation plans (prefer plan skill), or production code (prefer implement skill).'
---

# Spike — Workflow

A spike is **time-boxed research** for a single question that blocks development. One question per spike, evidence-based, ends with an actionable decision. If the question is already answered, write an `adr` instead.

## Phase 1 — Frame the Question

Reject vague spikes — refine until the question is sharp:

| Bad | Good |
|---|---|
| "Look into caching" | "Does Caffeine outperform Guava Cache for our 10k-entry hot-read workload?" |
| "Evaluate auth options" | "Can we replace homegrown session auth with Keycloak in <2 weeks?" |

A sharp question has: **a measurable answer** (yes/no, latency number, line-of-code estimate) and **a deadline**.

## Phase 2 — Collect Inputs

If the research question involves an external library, framework, or API, use Context7 to fetch authoritative docs before forming hypotheses. If Context7 is not available, fall back to web search or proceed with available context.

Required:

- **Title** — the focused question
- **Category** — `api` / `architecture` / `performance` / `platform` / `security` / `ux`
- **Timebox** — concrete duration (e.g. `1 week`, `3 days`)
- **Owner** — who runs it
- **Decision deadline** — when blocking will become critical

If the user can't define a timebox, push back — open-ended research is not a spike.

## Phase 3 — Locate Folder & Filename

```bash
ls docs/spikes/ 2>/dev/null || mkdir -p docs/spikes
```

Filename: `[category]-[short-description]-spike.md` (kebab-case).
Examples: `api-copilot-chat-integration-spike.md`, `performance-audio-latency-spike.md`.

## Phase 4 — Draft Using Template

```md
---
title: "[Spike Title]"
category: "[Category]"
status: "Not Started"
priority: "High"
timebox: "[Duration]"
created: [YYYY-MM-DD]
updated: [YYYY-MM-DD]
owner: "[Owner]"
tags: ["technical-spike", "[category]", "research"]
---

# [Spike Title]

## Summary

- **Objective:** [Specific question or decision]
- **Why it matters:** [Impact on development / architecture]
- **Timebox:** [Time allocated]
- **Decision deadline:** [When to resolve]

## Research Questions

**Primary:** [Main question]

**Secondary:**
- [Related question 1]
- [Related question 2]

## Investigation Plan

- [ ] [Research task 1]
- [ ] [Research task 2]
- [ ] [Build proof of concept]
- [ ] [Document findings]

## Success Criteria

Spike is complete when:

- [ ] [Criterion 1]
- [ ] Clear recommendation documented
- [ ] PoC completed (if applicable)

## Technical Context

- **Components:** [Affected system components]
- **Dependencies:** [Other spikes / decisions this blocks or is blocked by]
- **Constraints:** [Known limitations or requirements]

## Findings

[Research notes, test results, evidence — populated during the spike]

### External Resources

- [Link to docs / API / examples]

## Decision

- **Recommendation:** [Chosen approach]
- **Rationale:** [Why over alternatives]
- **Implementation notes:** [Key considerations]

**Follow-up:**

- [ ] [Action 1]
- [ ] Update architecture docs / write ADR
- [ ] Create implementation tasks

## Status

| Date | Status | Notes |
|---|---|---|
| [Date] | Not Started | Created |
| [Date] | In Progress | Research started |
| [Date] | Complete | [Resolution] |
```

## Rules

- One question per spike — split if there are multiple
- Always time-boxed — no open-ended research
- Evidence-based — prototypes, measurements, cited docs; not opinion
- Every spike ends with an actionable decision; if the timebox expires without one, that's a finding too

## Handoffs

- → `adr` skill — once the recommendation is decided, formalize it
- → `plan` skill — turn the recommendation into an executable plan
