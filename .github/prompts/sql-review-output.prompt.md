---
agent: 'agent'
# tools: sanctioned exception per STYLE-GUIDE line 271 — this -output prompt
# functions as an active review workflow and needs tools at invocation time.
tools: ['search/changes', 'search/codebase', 'edit/editFiles', 'read/problems']
description: 'SQL review workflow for ${selection}. Applies rules from instructions/sql-rules.instructions.md. Works across MySQL, PostgreSQL, SQL Server, Oracle.'
---

# SQL Review

Review and optimize `${selection}` (or the entire project if no selection). Apply rules from `instructions/sql-rules.instructions.md`. Review workflow lives in `skills/sql-review/SKILL.md`. This prompt defines the output format and reference tables only.

## Workflow

The review workflow (inventory, security pass, EXPLAIN pass, anti-pattern scan) is defined in `skills/sql-review/SKILL.md`. This prompt defines the output format and reference tables only.

## EXPLAIN Signal Cheat Sheet

| Signal | Meaning | Likely fix |
|---|---|---|
| `type: ALL` / `Seq Scan` | Full table scan | Add index on filter column |
| `Using filesort` | Sort without index | Add index on ORDER BY column |
| `Using temporary` | Temp table built | Rewrite or add covering index |
| `rows` >> actual | Stale statistics | `ANALYZE TABLE` |
| Nested loop on big tables | Bad join order | Check join column indexes |

## Output Format

For each issue:

```
[SEVERITY] [Category] — Brief description
  Location: <table/view/procedure>:<line>
  Problem: <what is wrong + impact>
  Fix: <specific recommendation with code>
```

Severity: `CRITICAL` (security / data loss) / `WARNING` (performance, maintainability) / `SUGGESTION` (style).

End with: counts by severity, top 3 priority actions, and an EXPLAIN / execution-plan recommendation when performance issues are flagged.
