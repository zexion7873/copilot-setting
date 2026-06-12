---
agent: 'agent'
description: 'Find all callers and dependents of the selected method or class — impact analysis before making changes.'
---

Find the full impact scope of this method / class:

1. Direct callers (which files and methods call it)
2. Indirect dependents (callers of callers, up to two levels)
3. Related Spring XML config (if it is a bean)
4. Related hbm.xml mappings (if it involves an entity)

Output format: sorted by impact severity (direct callers > Spring XML / `hbm.xml` wiring > indirect dependents), with file paths and line numbers.
