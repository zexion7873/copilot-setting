---
agent: 'agent'
description: 'Generate MySQL migration and rollback scripts from hbm.xml or entity changes.'
---

Generate a MySQL migration script from this hbm.xml or entity change:

1. `ALTER TABLE` statements (add / modify / drop columns, indexes, FKs)
2. Corresponding rollback script (reversible DDL)
3. Data migration statements (if columns are renamed or merged, data must be moved)

Rules:
- Follow the schema conventions and migration-safety rules in `instructions/sql-ddl.instructions.md` (naming, `ALGORITHM=INSTANT`, idempotent chunked backfill, expand-contract renames, running-app compatibility) — do not restate them here
- Write migration first, then rollback, clearly separated
