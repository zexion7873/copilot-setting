---
agent: 'agent'
description: 'Check a service method for N+1 query problems — lazy loading, loop queries, missing eager fetches.'
---

Check this service method for N+1 query problems:

1. Is lazy loading triggered inside a loop (accessing collections or associations)?
2. Are SQL / ORM queries executed inside a loop?
3. Are there lazy associations solvable with the ORM's eager or batch fetch mechanism?

Output one entry per problem: location (`file:line`) → the triggering access (loop + lazy association) → fix (the ORM's eager-fetch or batch-fetch idiom). If the method is N+1-clean, say so in one line — do not pad with a per-check explanation.
