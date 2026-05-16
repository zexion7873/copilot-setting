---
agent: 'agent'
description: 'Check transaction boundary correctness — self-invocation, rollback-for, read-only, and tx:advice coverage.'
---

Check the transaction boundaries of this code for correctness:

1. **tx:advice coverage**: Is this service method matched by an `<aop:config>` pointcut?
2. **Self-invocation**: Does `this.xxx()` call another method requiring its own transaction? (Bypasses AOP proxy)
3. **Rollback rules**: Are checked exceptions thrown without setting `rollback-for`?
4. **Read-only**: Are query methods marked `read-only="true"`? (`get*`, `find*`, `list*`, `count*`)
5. **Session usage**: Is manual `beginTransaction()` / `commit()` conflicting with `<tx:advice>`?
