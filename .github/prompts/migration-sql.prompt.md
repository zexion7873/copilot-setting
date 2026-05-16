---
agent: 'agent'
description: 'Generate MySQL migration and rollback scripts from hbm.xml or entity changes.'
---

根據這個 hbm.xml 或 entity 的變更，產生 MySQL migration script：

1. `ALTER TABLE` 語句（新增/修改/刪除欄位、索引、FK）
2. 對應的 rollback script（可以還原的 DDL）
3. 資料遷移語句（如果欄位改名或合併，需要搬資料）

規則：
- InnoDB engine、utf8mb4
- FK 命名：`fk_<child>_<parent_col>`
- 索引命名：`idx_<table>_<columns>`
- 先寫 migration，再寫 rollback，分開標示
