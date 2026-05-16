---
agent: 'agent'
description: 'Find all callers and dependents of the selected method or class — impact analysis before making changes.'
---

找出這個 method / class 的完整影響範圍：

1. 直接呼叫者（哪些檔案、哪些方法呼叫了它）
2. 間接依賴（呼叫者的呼叫者，最多兩層）
3. 相關的 Spring XML 設定（如果是 bean 的話）
4. 相關的 hbm.xml mapping（如果涉及 entity 的話）

輸出格式：按影響程度排序，標示檔案路徑和行號。
