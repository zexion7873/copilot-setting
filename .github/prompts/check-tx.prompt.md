---
agent: 'agent'
description: 'Check transaction boundary correctness — self-invocation, rollback-for, read-only, and tx:advice coverage.'
---

檢查這段 code 的 transaction 邊界是否正確：

1. **tx:advice 覆蓋**：這個 service method 有沒有被 `<aop:config>` pointcut 匹配到？
2. **Self-invocation**：有沒有 `this.xxx()` 呼叫另一個需要獨立 transaction 的方法？（會繞過 AOP proxy）
3. **Rollback 規則**：有沒有拋 checked exception 但忘了設 `rollback-for`？
4. **Read-only**：查詢方法有沒有標 `read-only="true"`？（`get*`, `find*`, `list*`, `count*`）
5. **Session 用法**：有沒有手動 `beginTransaction()` / `commit()` 跟 `<tx:advice>` 打架？
