---
agent: 'agent'
description: 'Generate Javadoc for the selected class or method — purpose, parameters, return value, exceptions.'
---

為選取的 class 或 method 撰寫 Javadoc：

- `@param` 每個參數的用途和限制
- `@return` 回傳值的意義（包含 null 的情況）
- `@throws` 可能拋出的 exception 和觸發條件
- 開頭一句話描述這個 method/class 做什麼

規則：
- Javadoc 用英文寫
- 不要描述顯而易見的事（getter/setter 不需要 Javadoc）
- 重點放在 contract（呼叫者需要知道什麼），不是 implementation
