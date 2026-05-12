# 全域 GitHub Copilot 設定

[English](README.md) | **繁體中文**

[![License: MIT](https://img.shields.io/github/license/zexion7873/copilot-setting?style=flat)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/stargazers)
[![Last commit](https://img.shields.io/github/last-commit/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/commits)
[![GitHub issues](https://img.shields.io/github/issues/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting/issues)
[![Repo size](https://img.shields.io/github/repo-size/zexion7873/copilot-setting?style=flat)](https://github.com/zexion7873/copilot-setting)

個人 Copilot 設定。部分檔案參考自 [awesome-copilot](https://github.com/github/awesome-copilot)，並依需求調整。

## 目錄結構

```
~/.github/
├── copilot-instructions.md                ← 全域基礎指示（客製）
│
├── instructions/                          ← 依 applyTo 規則自動套用
│   ├── context7
│   ├── context-engineering
│   ├── global-copilot
│   ├── javadoc
│   ├── junit
│   ├── markdown
│   ├── no-heredoc
│   ├── oop-design-patterns
│   ├── security-and-owasp
│   ├── self-explanatory-code-commenting
│   ├── sql-rules
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
├── prompts/                               ← 標準/輸出格式參考，與 skill 配對使用
│   ├── code-review-checklist
│   └── sql-review
│
└── skills/                                ← Agent 可執行的技能
    ├── adr/
    ├── clarify-task/
    ├── code-review/
    ├── context-discovery/
    ├── debug/
    ├── git-commit/
    ├── implement/
    ├── performance/
    ├── plan/
    ├── refactor/
    ├── security-audit/
    ├── spike/
    ├── sql-review/
    └── test-design/
```

---

## copilot-instructions.md（客製）

每次對話都會自動載入的全域基礎指示。

- 以繁體中文回覆
- 程式碼中的註解、變數名稱、類別名稱一律使用英文
- 技術環境：Java 8、Maven、無 Spring Boot
- 包含程式碼風格、錯誤處理、Git 慣例、Logging 規範

> **為什麼 `global-copilot.instructions.md` 內容一樣？**
>
> Copilot 透過兩個獨立的 scope 載入指示：
>
> | Scope | 載入機制 | 對應檔案 |
> |-------|----------|----------|
> | **Project** | Copilot 自動載入 `.github/copilot-instructions.md`（內建慣例） | `copilot-instructions.md` |
> | **User** | VS Code setting 指向 `~/.github/instructions/` 路徑 | `global-copilot.instructions.md` |
>
> Project scope 的載入機制無法引用 instructions 資料夾內的檔案，因此內容必須各放一份。這是 Copilot 平台的限制，並非意外重複。

---

## Instructions（指示）

當目前編輯的檔案符合 `applyTo` glob 時，自動注入 system prompt。

| 檔案 | applyTo | 說明 |
|------|---------|------|
| `context7` | `**` | 透過 Context7 MCP 取得權威的外部文件與 API 參考 |
| `context-engineering` | `**` | 優化程式碼與專案結構，讓 Copilot 更有效理解上下文 |
| `global-copilot` | `**` | 全域編碼標準、慣例與規範 |
| `javadoc` | `**/*.java` | Javadoc 規範 — 必要標籤、摘要句、格式與反模式 |
| `junit` | `**/*Test.java, **/*IT.java, **/test/**/*.java` | JUnit 5 + Mockito 規範 — 命名、AAA、參數化測試、斷言 |
| `markdown` | `**/*.md` | 遵循 CommonMark 規範（0.31.2）的 Markdown 格式 |
| `no-heredoc` | `**` | 防止終端機 heredoc 導致檔案毀損，強制使用檔案編輯工具 |
| `oop-design-patterns` | `**/*.{py,java,ts,js,cs}` | OOP 設計模式（GoF + SOLID） |
| `security-and-owasp` | `**/*.{java,jsp}` | 基於 OWASP Top 10 的安全編碼 |
| `self-explanatory-code-commenting` | `**/*.{java,js,ts,py,cs}` | 撰寫自解釋程式碼，減少冗餘註解 |
| `sql-rules` | `**/*.{java,sql,xml,jsp}` | SQL 硬規則：injection 防護、效能、程式碼品質（單一來源） |
| `sql-sp-generation` | `**/*.sql` | MySQL 預存程序與 schema 慣例 |

---

## Agents（代理人）

在 Copilot Chat 中輸入 `@agent-name` 呼叫。所有 agent 皆針對 Java 8 / Maven 專案客製。

| Agent | Model | 說明 |
|-------|-------|------|
| `@planner` | Claude Opus 4.6 | 分析需求、拆解任務、評估影響範圍 |
| `@implementer` | GPT-5.3-Codex | 撰寫符合規範的生產級 Java 程式碼 |
| `@reviewer` | Claude Opus 4.6 | 程式碼審查：正確性、安全性、效能、可維護性 |
| `@test-designer` | Claude Sonnet 4.6 | 設計完整測試案例（正常路徑、邊界、異常） |
| `@debugger` | Claude Opus 4.6 | 分析堆疊追蹤、追蹤執行流程來除錯 |
| `@refactorer` | Claude Sonnet 4.6 | 在不改變行為的前提下改善程式碼結構 |
| `@sql-expert` | Claude Sonnet 4.6 | SQL 撰寫、優化、審查與效能分析 |
| `@doc-writer` | GPT-5 mini | 撰寫 SDD、Javadoc、API 文件、遷移指南 |
| `@security` | Claude Opus 4.6 | 基於 OWASP Top 10 的 Java Web 安全審查 |

### Agent Handoffs 工作流程

Agent 間可互相交接任務，形成協作工作流：

```mermaid
flowchart LR
    Planner -->|"寫成 SDD"| DocWriter[Doc Writer]
    Planner -->|"開始實作"| Implementer
    Planner -->|"安全性評估"| Security

    DocWriter -->|"開始實作"| Implementer
    DocWriter -->|"回到規劃"| Planner

    Implementer -->|"Code Review"| Reviewer
    Implementer -->|"寫測試"| TestDesigner[Test Designer]
    Implementer -->|"安全性審查"| Security

    Reviewer -->|"修復問題"| Implementer
    Reviewer -->|"重構程式碼"| Refactorer

    TestDesigner -->|"修復失敗測試"| Implementer

    Refactorer -->|"Code Review"| Reviewer
    Refactorer -->|"補寫測試"| TestDesigner

    Debugger -->|"修復 Bug"| Implementer

    SQLExpert[SQL Expert] -->|"Code Review"| Reviewer
    SQLExpert -->|"整合到程式碼"| Implementer

    Security -->|"修復漏洞"| Implementer
```

---

## 運作機制

你只管切 **agent**，其他的自己來。

| 資源 | 何時載入 | 你要做什麼 |
|------|----------|-----------|
| **copilot-instructions.md** | 每次對話 | 不用動 — 永遠在 |
| **Instructions**（`instructions/`） | 檔案符合 `applyTo` glob（如 `**/*.java`） | 不用動 — 看你開什麼檔就注入什麼 |
| **Agents**（`agents/`） | 在 Chat 打 `@agent-name` | 選 agent |
| **Skills**（`skills/`） | Copilot 把你說的話比對 skill 的 `description` | 不用動 — 聊到就觸發 |
| **Prompts**（`prompts/`） | agent/skill 內部讀取，或你打 `/prompt-name` | 幾乎不用 — agent 自己會引用 |

## 典型工作流程

例子：加一支新的 API endpoint。

```
你  →  @planner       「我需要一支依客戶 ID 查訂單歷史的 API」
                       Planner 掃 codebase，拆出分階段計畫
                       ↓ 點「寫成 SDD」

你  →  @doc-writer    把計畫寫成 System Design Document
                       ↓ 點「開始實作」

你  →  @implementer   照 SDD 和既有 pattern 寫 code
                       ↓ 點「Code Review」

你  →  @reviewer      查正確性、安全性、效能
                       抓到 SQL injection → CRITICAL
                       ↓ 點「修復問題」

你  →  @implementer   改成 PreparedStatement
                       ↓ 點「寫測試」

你  →  @test-designer 設計測試（正常、null 客戶、分頁邊界）
                       Done ✓
```

每個 `↓` 是 VS Code 裡的 handoff 按鈕，下一個 agent 拿到完整對話脈絡，全程同一個聊天視窗。

> **其他常見起手式：**
> - Bug → `@debugger` → `@implementer`
> - SQL 太慢 → `@sql-expert` → `@reviewer`
> - 資安 → `@security` → `@implementer`
> - 寫文件 → `@planner` → `@doc-writer`

---

## Prompts（提示模板）

標準與輸出格式參考，與 skill 配對使用。在 Copilot Chat 中以 `/prompt-name` 手動呼叫，或讓配對的 skill 自動引用。

| Prompt | 配對 skill | 用途 |
|--------|------------|------|
| `code-review-checklist` | `code-review` | 嚴重度分類與各類別檢查項目 |
| `sql-review` | `sql-review` | 審查工作流的輸出格式（跨方言：MySQL/PostgreSQL/SQL Server/Oracle） |

---

## Skills（技能）

可執行的工作流。Copilot 判斷相關時自動觸發（除非停用），也可手動以 `/skill-name` 呼叫。

| Skill | 觸發方式 | 說明 |
|-------|----------|------|
| `adr` | 自動 + 手動 | 架構決策記錄 — 包含狀態、替代方案、後果分析 |
| `clarify-task` | 自動 + 手動 | 互動式任務釐清 — 動手前以編號問題確認範圍 |
| `code-review` | 自動 + 手動 | 結構化程式碼審查，含問題分類與最終裁定 |
| `context-discovery` | 自動 + 手動 | 動手前的 context map — 待修改檔案、相依、測試、參考模式 |
| `debug` | 自動 + 手動 | 系統化除錯，假說排序與二分隔離 |
| `git-commit` | **僅手動** | Conventional Commit 訊息產生與智慧檔案暫存 |
| `implement` | 自動 + 手動 | 功能實作 — 探索既有 pattern、開發、自我驗證 |
| `performance` | 自動 + 手動 | Measure-first 效能調校，涵蓋前端、Java 後端、資料庫 |
| `plan` | 自動 + 手動 | 結構化實作計畫 — 階段、原子任務、驗收標準 |
| `refactor` | 自動 + 手動 | 漸進式重構 — 擷取、重命名、消除異味 |
| `security-audit` | 自動 + 手動 | OWASP Top 10 審查與嚴重度分類 |
| `spike` | 自動 + 手動 | 限時技術探針文件，針對單一問題的研究 |
| `sql-review` | 自動 + 手動 | SQL 審查 — 注入防護、索引策略、反模式偵測 |
| `test-design` | 自動 + 手動 | 測試設計 — 邊界識別、JUnit 5 實作、覆蓋率分析 |

> `git-commit` 在 description 中標記為**僅手動**，因為它會修改 git history。Copilot 靠 description 文字抑制自動觸發；請一律以 `/git-commit` 顯式呼叫。
