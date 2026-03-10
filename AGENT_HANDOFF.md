# 🤖 Agent 交接文檔 — Legado iOS Reader

> **最後更新**: 2026-03-10
> **目標**: 將 Android Legado 閱讀器移植到 iOS（使用 Flutter）
> **當前階段**: Phase 2 — 解析引擎核心實作中

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
| Git | 已安裝 | 專案已 `git init`，首次 commit 已完成 |
| Android SDK | `C:\Users\benny\AppData\Local\Android\Sdk` | 可使用 Android 模擬器測試 |
| Mac / Xcode | ❌ 無 | iOS 打包需依賴 Codemagic 雲端服務 |

### 重要的 Shell 規範
- **必須使用** `& 'C:\Program Files\PowerShell\7\pwsh.exe' -NoProfile -Command "..."` 執行指令
- 涉及 `$`、`"` 或複雜路徑時，寫入 `.ps1` 暫存檔再用 `-File` 執行
- 禁止使用 CMD 風格指令 (`dir /s /b` 等)

---

## 📁 目前檔案結構（23 個 Dart 檔案）

```
ios/lib/
├── main.dart                                    ← App 入口 + 底部導航 (4 tabs)
│
├── core/                                        ← 核心層（平台無關的業務邏輯）
│   ├── models/                                  ← 資料模型 ✅ 已完成
│   │   ├── book.dart                            ← Book 書籍模型 (含 fromJson/toJson/copyWith)
│   │   ├── book_source.dart                     ← BookSource + 5 個子規則模型 (Search/Explore/BookInfo/Toc/Content)
│   │   ├── chapter.dart                         ← BookChapter 章節模型
│   │   ├── search_book.dart                     ← SearchBook 搜尋結果模型
│   │   └── replace_rule.dart                    ← ReplaceRule 替換規則模型
│   │
│   ├── engine/                                  ← 🔑 解析引擎（最核心，部分已完成）
│   │   ├── analyze_rule.dart                    ← AnalyzeRule 規則總控 ❌ STUB
│   │   ├── analyze_url.dart                     ← AnalyzeUrl URL 構建器 ❌ STUB (有 Dio 基礎框架)
│   │   ├── rule_analyzer.dart                   ← 規則字串切割器 ✅ 已完成
│   │   ├── parsers/
│   │   │   ├── analyze_by_css.dart              ← CSS 選擇器解析器 ❌ STUB
│   │   │   ├── analyze_by_json_path.dart        ← JsonPath 解析器 ❌ STUB
│   │   │   ├── analyze_by_xpath.dart            ← XPath 解析器 ✅ 已完成
│   │   │   └── analyze_by_regex.dart            ← 正則解析器 ✅ 已完成
│   │   └── js/
│   │       └── js_engine.dart                   ← JS 執行引擎 ❌ STUB
│   │
│   ├── services/
│   │   └── book_source_service.dart             ← 書源業務服務 ❌ STUB (介面已定義)
│   │
│   └── database/
│       └── app_database.dart                    ← SQLite 資料庫 ✅ Schema 已定義 (6 個表)
│
├── features/                                    ← UI 功能頁面（全部為 skeleton）
│   ├── bookshelf/bookshelf_page.dart            ← 書架頁 ❌ STUB
│   ├── explore/explore_page.dart                ← 發現頁 ❌ STUB
│   ├── search/search_page.dart                  ← 搜尋頁 ❌ STUB (有 TextField)
│   ├── reader/reader_page.dart                  ← 閱讀器 ❌ STUB
│   ├── source_manager/source_manager_page.dart  ← 書源管理 ❌ STUB
│   └── settings/settings_page.dart              ← 設定頁 ❌ STUB (有選單結構)
│
└── shared/
    └── theme/app_theme.dart                     ← 主題 ✅ 已完成 (Material 3 + 5 套閱讀主題)
```

---

## 📦 pubspec.yaml 依賴（已完成 pub get）

```yaml
# 已宣告的依賴:
provider: ^6.1.2        # 狀態管理
dio: ^5.7.0             # HTTP 請求 (替代 OkHttp)
sqflite: ^2.4.1         # SQLite (替代 Room)
html: ^0.15.5           # HTML 解析 (替代 Jsoup)
csslib: ^1.0.0          # CSS 解析
json_path: ^0.7.4       # JsonPath (替代 jayway json-path)
xpath_selector: ^3.0.2  # XPath
xpath_selector_html_parser: ^3.0.1
flutter_js: ^0.8.3      # JS 引擎 (替代 Rhino)
crypto: ^3.0.6          # 加密工具
encrypt: ^5.0.3         # AES/RSA
pointycastle: ^3.9.1    # 進階加密
cached_network_image: ^3.4.1
file_picker: ^8.1.7     # 本地檔案
webview_flutter: ^4.10.0 # WebView 載入模式
shared_preferences: ^2.3.4
uuid: ^4.5.1
intl: ^0.19.0
```

---

## 🔑 Android 原始碼對照表（翻譯參考）

### 解析引擎 (`legado/app/src/main/java/io/legado/app/model/analyzeRule/`)

| Android 檔案 | 大小 | iOS 對應 | 優先級 | 狀態 | 說明 |
|-------------|------|---------|--------|------|------|
| `AnalyzeRule.kt` | 32KB | `engine/analyze_rule.dart` | P0 | ❌ STUB | **最核心**。規則前綴分流、`&&`/`||` 邏輯、`@put/@get`、`{{js}}` |
| `RuleAnalyzer.kt` | 15KB | `engine/rule_analyzer.dart` | P0 | ✅ 已完成 | 規則字串切割器，已通過單元測試。 |
| `AnalyzeUrl.kt` | 29KB | `engine/analyze_url.dart` | P0 | ❌ STUB | URL 模板解析，POST/GET 分流，`{{key}}`/`{{page}}` 替換 |
| `AnalyzeByJSoup.kt` | 18KB | `engine/parsers/analyze_by_css.dart` | P0 | ❌ STUB | **CSS 選擇器 + 屬性提取**。支援 `tag.class@attr` |
| `AnalyzeByJSonPath.kt` | 6KB | `engine/parsers/analyze_by_json_path.dart` | P0 | ❌ STUB | JsonPath 查詢 |
| `AnalyzeByXPath.kt` | 5KB | `engine/parsers/analyze_by_xpath.dart` | P1 | ✅ 已完成 | XPath 節點與屬性提取。 |
| `AnalyzeByRegex.kt` | 2KB | `engine/parsers/analyze_by_regex.dart` | P1 | ✅ 已完成 | 正則 `##pattern##replacement` 與鏈式提取。 |
| `QueryTTF.java` | 39KB | (暫不實作) | P3 | - | 字體反爬 |
| `RuleData.kt` | 1KB | (合併至 analyze_rule.dart) | P0 | - | 規則上下文數據介面 |
| `CustomUrl.kt` | 1KB | (合併至 analyze_url.dart) | P1 | - | 自訂 URL 處理 |

### 書源業務邏輯 (`legado/app/src/main/java/io/legado/app/model/webBook/`)

| Android 檔案 | 大小 | iOS 對應 | 說明 |
|-------------|------|---------|------|
| `WebBook.kt` | 15KB | `services/book_source_service.dart` | 統一入口：搜尋、書籍資訊、目錄、正文 |
| `BookList.kt` | 13KB | (整合至 book_source_service.dart) | 搜尋/發現結果列表解析 |
| `BookInfo.kt` | 7KB | (整合至 book_source_service.dart) | 書籍詳情頁解析 |
| `BookChapterList.kt` | 13KB | (整合至 book_source_service.dart) | 章節目錄解析(含翻頁 nextTocUrl) |
| `BookContent.kt` | 9KB | (整合至 book_source_service.dart) | 正文內容解析(含翻頁 nextContentUrl) |
| `SearchModel.kt` | 8KB | (需新建 `services/search_model.dart`) | 多源並發搜尋、結果聚合 |

---

## 🎯 實作順序

### 第 2 步：解析引擎（核心中的核心）
**按此順序實作，每完成一個就寫測試：**

1. **`analyze_by_json_path.dart`** — ❌ 待實作 (參考 AnalyzeByJSonPath.kt)
2. **`analyze_by_css.dart`** — ❌ 待實作 (參考 AnalyzeByJSoup.kt)
3. **`analyze_by_xpath.dart`** — ✅ 已完成 (單元測試通過)
4. **`analyze_by_regex.dart`** — ✅ 已完成 (單元測試通過)
5. **`rule_analyzer.dart`** — ✅ 已完成 (單元測試通過)
6. **`analyze_rule.dart`** — ❌ 下一步重點
7. **`analyze_url.dart`** — ❌ 下一步重點

---

## ⚠️ 關鍵注意事項 (重要!)

1. **Legado 自創的 CSS 語法**：
   `div.result@tag.a!0@href` 這種語法必須在 `analyze_by_css.dart` 中手動解析。
2. **RuleAnalyzer**：
   此組件已穩定，實作 `AnalyzeRule` 時務必調用其 `splitRule` 處理 `&&` 與 `||`，並用 `innerRuleRange` 處理變數替換。
3. **JS 引擎**：
   下一步實作 `AnalyzeRule` 時，對於 `{{js}}` 區塊，目前可先保留 stub，待 Phase 3 整合 `flutter_js`。

---

## ✅ 已完成的部分 (本輪更新)

- [x] 實作 `lib/core/engine/rule_analyzer.dart` 並通過單元測試。
- [x] 實作 `lib/core/engine/parsers/analyze_by_xpath.dart` 並通過單元測試。
- [x] 實作 `lib/core/engine/parsers/analyze_by_regex.dart` 並通過單元測試。
- [x] 更新交接文檔 progress。
