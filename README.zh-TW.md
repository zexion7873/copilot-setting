# 全域 GitHub Copilot 設定

[English](README.md) | **繁體中文**

[![License: MIT](https://img.shields.io/github/license/zexion7873/copilot-setting?style=flat)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/stargazers)
[![Last commit](https://img.shields.io/github/last-commit/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/commits)
[![GitHub issues](https://img.shields.io/github/issues/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/issues)
[![Repo size](https://img.shields.io/github/repo-size/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting)

個人全域 Copilot 設定，適用於所有工作區。
初始架構參考自 [awesome-copilot](https://github.com/microsoft/awesome-copilot)，並依個人需求調整。

## 目錄結構

```
~/.github/
├── copilot-instructions.md                ← 全域基礎指示（客製）
│
├── instructions/                          ← 依 applyTo 規則自動套用
│   ├── code-review-generic
│   ├── context7
│   ├── context-engineering
│   ├── markdown
│   ├── no-heredoc
│   ├── oop-design-patterns
│   ├── performance-optimization
│   ├── security-and-owasp
│   ├── self-explanatory-code-commenting
│   └── sql-sp-generation
│
├── agents/                                ← 在聊天中以 @agent-name 呼叫
│   ├── planner              (Claude Opus 4.6)
│   ├── implementer          (GPT-5.3-Codex)
│   ├── reviewer             (Claude Opus 4.6)
│   ├── test-designer        (Claude Sonnet 4.6)
│   ├── debugger             (Claude Opus 4.6)
│   ├── refactorer           (Claude Sonnet 4.6)
│   ├── sql-expert           (Claude Sonnet 4.6)
│   ├── doc-writer           (GPT-5 mini)
│   └── security             (Claude Opus 4.6)
│
├── prompts/                               ← 可重複使用的提示模板
│   ├── context-map
│   ├── conventional-commit
│   ├── create-architectural-decision-record
│   ├── create-implementation-plan
│   ├── create-technical-spike
│   ├── first-ask
│   ├── java-docs
│   ├── java-junit
│   ├── java-refactoring-extract-method
│   ├── java-refactoring-remove-parameter
│   ├── refactor-plan
│   ├── review-and-refactor
│   ├── sql-code-review
│   ├── sql-optimization
│   └── what-context-needed
│
└── skills/                                ← Agent 可執行的技能
    ├── git-commit/
    └── refactor/
```

---

## copilot-instructions.md（客製）

每次對話都會自動載入的全域基礎指示。

- 以繁體中文回覆
- 所有程式碼、註解、變數名稱使用英文
- 技術環境：Java 8、Maven、無 Spring Boot
- 包含程式碼風格、錯誤處理、安全性、效能規範

---

## Instructions（指示）

依照 `applyTo` glob 規則（如 `**/*.java`、`**/*.sql`）自動套用至匹配的檔案。

| 檔案 | 說明 |
|------|------|
| `code-review-generic` | 通用程式碼審查檢查清單，可依專案客製 |
| `context7` | 透過 Context7 MCP 取得權威的外部文件與 API 參考 |
| `context-engineering` | 優化程式碼與專案結構，讓 Copilot 能更有效理解上下文 |
| `markdown` | 遵循 CommonMark 規範（0.31.2）的 Markdown 格式 |
| `no-heredoc` | 防止終端機 heredoc 導致檔案毀損，強制使用檔案編輯工具 |
| `oop-design-patterns` | OOP 設計模式（GoF + SOLID）最佳實踐 |
| `performance-optimization` | 前端、後端、資料庫全方位效能最佳化指南 |
| `security-and-owasp` | 基於 OWASP Top 10 的安全編碼指南 |
| `self-explanatory-code-commenting` | 撰寫自解釋程式碼，減少冗餘註解 |
| `sql-sp-generation` | MySQL SQL 語句與預存程序的產生規範 |

---

## Agents（自訂代理人）

在 Copilot Chat 中輸入 `@agent-name` 呼叫。所有 agent 皆針對 Java 8 / Maven 專案客製。

| Agent | Model | 說明 |
|-------|-------|------|
| `@planner` | Claude Opus 4.6 | 分析需求、拆解任務、評估影響範圍 |
| `@implementer` | GPT-5.3-Codex | 撰寫符合規範的生產級 Java 程式碼 |
| `@reviewer` | Claude Opus 4.6 | 全面程式碼審查：正確性、安全性、效能、可維護性 |
| `@test-designer` | Claude Sonnet 4.6 | 設計完整測試案例（正常路徑、邊界、異常） |
| `@debugger` | Claude Opus 4.6 | 系統化除錯：分析堆疊追蹤、追蹤執行流程 |
| `@refactorer` | Claude Sonnet 4.6 | 在不改變行為的前提下改善程式碼結構 |
| `@sql-expert` | Claude Sonnet 4.6 | SQL 撰寫、優化、審查與效能分析 |
| `@doc-writer` | GPT-5 mini | 撰寫 SDD、Javadoc、API 文件、遷移指南 |
| `@security` | Claude Opus 4.6 | 基於 OWASP Top 10 的 Java Web 安全審查 |

---

## Prompts（提示模板）

可重複使用的提示模板，透過提示選擇器或 `/` 引用。

### 上下文與規劃

| Prompt | 說明 |
|--------|------|
| `context-map` | 修改前產生所有相關檔案的地圖 |
| `first-ask` | 互動式任務釐清 — 先確認範圍、交付物、限制再行動 |
| `what-context-needed` | 回答問題前先讓 Copilot 列出需要查看的檔案 |
| `create-implementation-plan` | 為功能開發、重構或升級建立結構化實作計畫 |
| `create-technical-spike` | 建立限時技術探針文件以解決關鍵技術決策 |
| `create-architectural-decision-record` | 建立架構決策記錄（ADR）文件 |

### Java

| Prompt | 說明 |
|--------|------|
| `java-docs` | 依最佳實務產生 Javadoc 註解 |
| `java-junit` | JUnit 5 單元測試最佳實務，含資料驅動測試 |
| `java-refactoring-extract-method` | Java 擷取方法（Extract Method）重構 |
| `java-refactoring-remove-parameter` | Java 移除參數（Remove Parameter）重構 |

### SQL

| Prompt | 說明 |
|--------|------|
| `sql-code-review` | SQL 安全性、可維護性與品質審查（MySQL/PostgreSQL/SQL Server/Oracle） |
| `sql-optimization` | SQL 效能優化 — 查詢調校、索引策略、執行計畫分析 |

### 程式碼品質與 Git

| Prompt | 說明 |
|--------|------|
| `review-and-refactor` | 依定義的規範審查並重構程式碼 |
| `refactor-plan` | 規劃多檔案重構的順序與回滾步驟 |
| `conventional-commit` | 產生符合 Conventional Commits 規範的提交訊息 |

---

## Skills（技能）

Agent 可呼叫的可執行技能。

| Skill | 說明 |
|-------|------|
| `git-commit` | 自動偵測變更、產生 Conventional Commit 訊息、智慧檔案暫存 |
| `refactor` | 漸進式程式碼重構 — 擷取函式、重命名變數、消除程式碼異味 |
