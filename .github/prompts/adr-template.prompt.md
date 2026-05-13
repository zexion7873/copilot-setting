---
agent: 'agent'
description: 'ADR (Architectural Decision Record) template with Status, Context, Decision, Consequences, Alternatives, and Implementation Notes. Pairs with skills/adr/SKILL.md (workflow / sequence numbering / validation).'
---

# ADR Template

One-shot scaffold for an Architectural Decision Record. Workflow (input collection, sequence numbering, validation) lives in `skills/adr/SKILL.md`. ADRs capture **decisions already made** — for open research, use the `spike` skill.

## Usage

Invoke via `/adr-template`. ADR filename convention: `docs/adr/adr-NNNN-[title-slug].md` with a 4-digit zero-padded sequence number. Status starts at `Proposed`.

## Template

```md
---
title: "ADR-${input:adrNumber:0001}: ${input:title:Decision title}"
status: "${input:status:Proposed}"
date: "${input:date:YYYY-MM-DD}"
authors: "${input:authors}"
tags: ["architecture", "decision"]
supersedes: ""
superseded_by: ""
---

# ADR-${input:adrNumber}: ${input:title}

## Status

**Proposed** | Accepted | Rejected | Superseded | Deprecated

## Context

[Problem statement. Technical constraints. Business requirements. Environmental factors. Why this decision is being made now.]

## Decision

[The chosen solution, stated as a clear declarative sentence. Followed by rationale paragraphs covering the most important trade-offs.]

## Consequences

### Positive

- POS-001: [Beneficial outcome — e.g., performance gain, easier maintenance]
- POS-002: [Capability unlocked]

### Negative

- NEG-001: [Trade-off accepted — e.g., increased operational complexity]
- NEG-002: [Technical debt or new risk introduced]

## Alternatives Considered

### [Alternative 1 Name]

- ALT-001: **Description**: [Brief technical description of the alternative]
- ALT-002: **Rejection Reason**: [Why this was not chosen — be specific, not vague]

### [Alternative 2 Name]

- ALT-003: **Description**: ...
- ALT-004: **Rejection Reason**: ...

## Implementation Notes

- IMP-001: [Key implementation consideration]
- IMP-002: [Migration / rollout strategy if applicable]
- IMP-003: [Monitoring or validation approach post-rollout]

## References

- REF-001: [Related ADRs — e.g., supersedes ADR-0003, related to ADR-0008]
- REF-002: [External documentation, RFC, paper, blog post]
- REF-003: [Internal spec or plan that motivated this decision]
```

## Validation Checklist

- [ ] Every `${input:...}` placeholder replaced
- [ ] Filename matches `adr-NNNN-[title-slug].md` (4-digit zero-padded)
- [ ] Status starts at `Proposed` (updated to `Accepted` after review)
- [ ] At least one alternative documented with a rejection reason
- [ ] Both POSITIVE and NEGATIVE consequences listed — a decision with no downside is suspect
- [ ] Coded identifiers (`POS-`, `NEG-`, `ALT-`, `IMP-`, `REF-`) used for cross-reference
- [ ] No placeholder text left in the body
