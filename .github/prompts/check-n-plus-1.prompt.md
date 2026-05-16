---
agent: 'agent'
description: 'Check a service method for N+1 query problems — lazy loading, loop queries, missing JOIN FETCH.'
---

檢查這個 service method 有沒有 N+1 query 問題：

1. 有沒有在迴圈裡觸發 lazy loading（存取 collection 或 association）
2. 有沒有在迴圈裡執行 SQL / HQL query
3. 有沒有可以用 `JOIN FETCH` 或 `fetch="join"` 解決的 lazy collection

如果有問題，給出具體的修法（HQL JOIN FETCH 或 hbm.xml fetch 設定）。
