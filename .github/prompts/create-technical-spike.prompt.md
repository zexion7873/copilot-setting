---
agent: 'agent'
description: 'Create a time-boxed technical spike document for researching a single decision before implementation.'
tools: ['search/codebase', 'edit/editFiles', 'web/fetch', 'read/problems']
---

# Create Technical Spike Document

Create a time-boxed spike for a single technical question that must be answered before development can proceed. One question per spike, with a deadline and concrete deliverable.

## Output

- Location: `${input:FolderPath|docs/spikes}` directory
- Filename: `[category]-[short-description]-spike.md` (kebab-case)
- Common categories: `api`, `architecture`, `performance`, `platform`, `security`, `ux`
- Examples: `api-copilot-chat-integration-spike.md`, `performance-audio-latency-spike.md`

## Template

```md
---
title: "${input:SpikeTitle}"
category: "${input:Category|Technical}"
status: "Not Started"
priority: "${input:Priority|High}"
timebox: "${input:Timebox|1 week}"
created: [YYYY-MM-DD]
updated: [YYYY-MM-DD]
owner: "${input:Owner}"
tags: ["technical-spike", "${input:Category|technical}", "research"]
---

# ${input:SpikeTitle}

## Summary

- **Objective:** [Specific question or decision]
- **Why it matters:** [Impact on development / architecture]
- **Timebox:** [Time allocated]
- **Decision deadline:** [When to resolve to avoid blocking]

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

[Research notes, test results, evidence]

### External Resources

- [Link to docs / API / examples]

## Decision

- **Recommendation:** [Chosen approach]
- **Rationale:** [Why over alternatives]
- **Implementation notes:** [Key considerations]

**Follow-up:**

- [ ] [Action 1]
- [ ] Update architecture docs
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
- Evidence-based — prototypes / tests / cited docs, not opinion
- Every spike ends with an actionable decision
