---
agent: 'agent'
description: 'Find all callers and dependents of the selected method or class — impact analysis before making changes.'
---

Find the full impact scope of this method / class:

1. Direct callers (which files and methods call it)
2. Indirect dependents (callers of callers, up to two levels)
3. Related framework wiring / DI configuration (if it is a managed component)
4. Related ORM mapping files (if it involves a persisted entity)

Output format: sorted by impact severity (direct callers > framework wiring / ORM mappings > indirect dependents), with file paths and line numbers.
