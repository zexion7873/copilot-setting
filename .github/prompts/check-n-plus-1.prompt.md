---
agent: 'agent'
description: 'Check a service method for N+1 query problems — lazy loading, loop queries, missing JOIN FETCH.'
---

Check this service method for N+1 query problems:

1. Is lazy loading triggered inside a loop (accessing collections or associations)?
2. Are SQL / HQL queries executed inside a loop?
3. Are there lazy collections solvable with `JOIN FETCH` or `fetch="join"`?

If problems exist, provide specific fixes (HQL JOIN FETCH or hbm.xml fetch configuration).
