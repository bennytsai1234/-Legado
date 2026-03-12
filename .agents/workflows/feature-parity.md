---
description: "Legado Feature Parity Workflow - 逐模組還原 legado 功能至 iOS Flutter"
---

# Feature Parity 工作流

**目標**：以 `FEATURE_AUDIT_v2.md` 為追蹤器，逐一將 legado (Android) 的功能完整還原至 Flutter (iOS)。

## 工作流步驟（每個模組重複此循環）

### 步驟 1：分析 Legado 原始碼
// turbo
- 進入 `legado/app/src/main/java/io/legado/app/ui/<模組名>/` 目錄
- 讀取所有 `.kt` 檔案，理解功能邏輯、UI 互動流程、資料流

### 步驟 2：盤點 iOS 現有實作
// turbo
- 進入 `ios/lib/features/<對應模組>/` 目錄
- 讀取所有 `.dart` 檔案，確認已實作的功能與缺失的功能
- 對照步驟 1 的 Legado 功能清單，列出差異

### 步驟 3：實作缺失功能
- 根據差異清單，逐一在 Flutter 端實作缺失的功能
- 每完成一個檔案的修改，立即執行 `git add <file> ; git commit -m "backup: update <file>"`
- 確保新增的代碼遵循現有專案的架構風格

### 步驟 4：驗證
// turbo
- 執行 `flutter analyze lib/features/<模組名>/` 確認零錯誤
- 修復所有 warning（如 `withOpacity` → `withValues`）

### 步驟 5：更新報告
- 回到 `FEATURE_AUDIT_v2.md`
- 更新該模組的「完成度」百分比
- 更新「狀態」標籤
- 在模組內容區標註已完成的項目（✅）與剩餘待辦（如有）
- 執行 `git add FEATURE_AUDIT_v2.md ; git commit -m "docs: update module XX status"`

### 步驟 6：正式提交
- 將該模組的所有變更合併為一個正式的 conventional commit
- 格式：`feat(<模組名>): implement full feature parity for <模組描述>`

## 模組處理順序（01 ~ 10）

1. **01. 主框架 (Main)** — 90% → 100%
2. **02. 關於 (About)** — 65% → 100%
3. **03. 外部檔案關聯 (Association)** — 10% → 100%
4. **04. 有聲書 (Audio)** — 40% → 100%
5. **05. 全域書籤 (Bookmark)** — 70% → 100%
6. **06. 快取下載 (Cache)** — 65% → 100%
7. **07. 換封面 (ChangeCover)** — 100%
8. **08. 換源 (ChangeSource)** — 75% → 100%
9. **09. 發現探索 (Explore)** — 75% → 100%
10. **10. 書架分組管理 (Group/Manage)** — 45% → 100%

## 注意事項
- 若某功能因 iOS 平台限制完全無法實作（如 Android Intent），須在報告中註明原因並標記為「iOS 不適用」
- 每次只專注在一個模組，避免交叉修改
- 所有對話與解釋使用**繁體中文**
