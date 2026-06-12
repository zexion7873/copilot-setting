---
agent: 'agent'
description: 'Check a service method for N+1 query problems — lazy loading, loop queries, missing JOIN FETCH.'
---

Check this service method for N+1 query problems:

1. Is lazy loading triggered inside a loop (accessing collections or associations)?
2. Are SQL / HQL queries executed inside a loop?
3. Are there lazy collections solvable with `JOIN FETCH` or `fetch="join"`?

Output one entry per problem: location (`file:line`) → the triggering access (loop + lazy association) → fix (HQL `JOIN FETCH` or hbm.xml `fetch="join"`). If the method is N+1-clean, say so in one line — do not pad with a per-check explanation.
