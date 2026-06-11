---
agent: 'agent'
description: 'Generate MySQL migration and rollback scripts from hbm.xml or entity changes.'
---

Generate a MySQL migration script from this hbm.xml or entity change:

1. `ALTER TABLE` statements (add / modify / drop columns, indexes, FKs)
2. Corresponding rollback script (reversible DDL)
3. Data migration statements (if columns are renamed or merged, data must be moved)

Rules:
- InnoDB engine, utf8mb4
- FK naming: `fk_<child>_<parent_col>`
- Index naming: `idx_<table>_<columns>`
- Column renames / merges: never a single-shot `RENAME`/`CHANGE` — add the new column and backfill; drop the old column in a later release
- Write migration first, then rollback, clearly separated
