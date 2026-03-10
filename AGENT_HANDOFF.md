# 🤖 Agent 交接文檔 — Legado iOS Reader

> **最後更新**: 2026-03-10
> **目標**: 將 Android Legado 閱讀器移植到 iOS（使用 Flutter）
> **當前階段**: Phase 2 結束，即將進入 Phase 3 (JS 擴展與業務服務)

---

## 📍 專案位置

| 專案 | 路徑 | 說明 |
|------|------|------|
| **iOS Flutter 專案** | `c:\Users\benny\Desktop\Folder\Project\reader\ios\` | 你要實作的目標 |
| **Android 原始碼（參考）** | `c:\Users\benny\Desktop\Folder\Project\reader\legado\` | Kotlin/Java 原始碼，作為邏輯翻譯的參考來源 |

---

## 🛠️ 開發環境

| 工具 | 版本 | 備註 |
|------|------|------|
| OS | Windows | 使用 PowerShell 7 (`pwsh.exe`)，**禁止使用 `&&`**，用 `;` 代替 |
| Flutter | 3.29.1 (stable) | Dart 3.7.0 |
| IDE | Antigravity (VS Code-based) | 沒有 Java/Android 語言支援，Android 專案的 IDE 報錯可忽略 |
| Git | 已安裝 | 專案已 `git init`，最近一次 commit 已包含解析引擎核心 |

---

## 📁 目前檔案結構與實作狀態 (解析引擎)

```
ios/lib/
├── core/
│   ├── models/                                  ← 資料模型 ✅ 全部完成
│   │
│   ├── engine/                                  ← 🔑 解析引擎 ✅ 核心實作完成
│   │   ├── analyze_rule.dart                    ← AnalyzeRule 規則總控 ✅ 已完成 (含去重、分流、變數處理)
│   │   ├── analyze_url.dart                     ← AnalyzeUrl URL 構建器 ✅ 已完成 (含變數替換、Dio 請求)
│   │   ├── rule_analyzer.dart                   ← 規則字串切割器 ✅ 已完成 (平衡括號切割)
│   │   ├── parsers/
│   │   │   ├── analyze_by_css.dart              ← CSS 解析器 ✅ 已完成 (Legado 自創語法支援)
│   │   │   ├── analyze_by_json_path.dart        ← JsonPath 解析器 ✅ 已完成
│   │   │   ├── analyze_by_xpath.dart            ← XPath 解析器 ✅ 已完成
│   │   │   └── analyze_by_regex.dart            ← 正則解析器 ✅ 已完成 (支援 ## 替換)
│   │   └── js/
│   │       └── js_engine.dart                   ← JS 執行引擎 ✅ 基礎實作完成 (整合 flutter_js)
│   │
│   ├── services/
│   │   └── book_source_service.dart             ← 書源業務服務 ❌ STUB
│   │
│   └── database/
│       └── app_database.dart                    ← SQLite 資料庫 ✅ Schema 已定義
```

---

## 🔑 Android 原始碼對照表與進度

| Android 檔案 | iOS 對應 | 優先級 | 狀態 | 說明 |
|-------------|---------|--------|------|------|
| `AnalyzeRule.kt` | `engine/analyze_rule.dart` | P0 | ✅ 已完成 | 已通過整合測試 |
| `RuleAnalyzer.kt` | `engine/rule_analyzer.dart` | P0 | ✅ 已完成 | 支援複合規則處理 |
| `AnalyzeUrl.kt` | `engine/analyze_url.dart` | P0 | ✅ 已完成 | 支援 POST/GET 與變數替換 |
| `AnalyzeByJSoup.kt` | `engine/parsers/analyze_by_css.dart` | P0 | ✅ 已完成 | 核心 CSS 語法支援 |
| `AnalyzeByJSonPath.kt`| `engine/parsers/analyze_by_json_path.dart`| P0 | ✅ 已完成 | |
| `AnalyzeByXPath.kt` | `engine/parsers/analyze_by_xpath.dart` | P1 | ✅ 已完成 | |
| `AnalyzeByRegex.kt` | `engine/parsers/analyze_by_regex.dart` | P1 | ✅ 已完成 | |
| `JsExtensions.kt` | `engine/js/js_extensions.dart` | P0 | ❌ 待實作 | **下一輪重點**：`java.ajax`, `md5`, `aes` 等橋接 |
| `WebBook.kt` | `services/book_source_service.dart` | P0 | ❌ 待實作 | **下一輪重點**：搜尋/資訊/目錄/正文邏輯 |

---

## 🎯 下一階段任務 (交接給下個 Agent)

### 1. JS 擴展橋接 (Phase 3)
- 實作 `js_extensions.dart`：將 `AnalyzeRule` 注入到 `JsEngine` 的 bindings 中。
- 必須支援 `java.ajax(url)`、`java.base64Decode(str)`、`java.md5Encode(str)`。
- 這對於大多數需要複雜簽名的書源至關重要。

### 2. 書源業務邏輯 (Phase 4)
- 實作 `book_source_service.dart`：翻譯 `WebBook.kt` 及其附屬類別。
- 這層邏輯負責呼叫 `AnalyzeRule` 來填充 `Book` 與 `Chapter` 模型。

### 3. 資料庫 DAO 層 (Phase 5)
- 實作 `book_source_dao.dart` 與 `book_dao.dart`。

### 4. UI 介面實作 (Phase 6)
- 目前所有頁面皆為空白，優先實作「搜尋頁」以驗證解析引擎效果。

---

## ⚠️ 提醒
- **JS 執行環境**：在 Windows VM 測試環境中，`flutter_js` 可能因缺少原生庫而失敗，`js_engine.dart` 內建了基本的 mock 以供測試。實機運行無此問題。
- **解析器穩定性**：`AnalyzeRule` 與 `AnalyzeUrl` 已經過整合測試 (`test/core/engine/parsing_integration_test.dart`)，穩定性良好。
