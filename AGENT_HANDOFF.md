# 🤖 Agent 交接文檔 — Legado iOS Reader

> **最後更新**: 2026-03-10
> **目標**: 將 Android Legado 閱讀器移植到 iOS（使用 Flutter）
> **當前階段**: Phase 1 — 專案骨架已建立，所有檔案為 stub/skeleton，尚無實際功能

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

## 📁 目前檔案結構（22 個 Dart 檔案）

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
│   ├── engine/                                  ← 🔑 解析引擎（最核心，全部待實作）
│   │   ├── analyze_rule.dart                    ← AnalyzeRule 規則總控 ❌ STUB
│   │   ├── analyze_url.dart                     ← AnalyzeUrl URL 構建器 ❌ STUB (有 Dio 基礎框架)
│   │   ├── parsers/
│   │   │   ├── analyze_by_css.dart              ← CSS 選擇器解析器 ❌ STUB
│   │   │   ├── analyze_by_json_path.dart        ← JsonPath 解析器 ❌ STUB
│   │   │   ├── analyze_by_xpath.dart            ← XPath 解析器 ❌ STUB
│   │   │   └── analyze_by_regex.dart            ← 正則解析器 ❌ STUB
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

## 📦 pubspec.yaml 依賴（已定義但部分未 `pub get`）

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

> ⚠️ **注意**: 首次接手時請執行 `flutter pub get` 確保依賴安裝成功。若有版本衝突需調整。

---

## 🔑 Android 原始碼對照表（翻譯參考）

這是從 Android Kotlin/Java 翻譯到 Dart 時的核心對照。

### 解析引擎 (`legado/app/src/main/java/io/legado/app/model/analyzeRule/`)

| Android 檔案 | 大小 | iOS 對應 | 優先級 | 說明 |
|-------------|------|---------|--------|------|
| `AnalyzeRule.kt` | 32KB | `engine/analyze_rule.dart` | P0 | **最核心**。規則前綴分流(`@css:`,`@json:`,`@xpath:`,`@js:`)、`&&`/`||`/`%%` 邏輯、`@put/@get` 變數、`{{js}}` 內嵌 |
| `RuleAnalyzer.kt` | 15KB | (需新建 `engine/rule_analyzer.dart`) | P0 | 規則字串切割器，負責解析 `&&`, `||`, `%%`, `{{}}` 等結構 |
| `AnalyzeUrl.kt` | 29KB | `engine/analyze_url.dart` | P0 | URL 模板解析，POST/GET 分流，Header 處理，`{{key}}`/`{{page}}` 替換，webView 偵測 |
| `AnalyzeByJSoup.kt` | 18KB | `engine/parsers/analyze_by_css.dart` | P0 | **CSS 選擇器 + 屬性提取**。注意 Android 用 Jsoup，iOS 用 `html` package |
| `AnalyzeByJSonPath.kt` | 6KB | `engine/parsers/analyze_by_json_path.dart` | P0 | JsonPath 查詢(50%+書源使用 JSON API) |
| `AnalyzeByXPath.kt` | 5KB | `engine/parsers/analyze_by_xpath.dart` | P1 | XPath 節點選擇 |
| `AnalyzeByRegex.kt` | 2KB | `engine/parsers/analyze_by_regex.dart` | P1 | 正則 `##pattern##replacement` |
| `QueryTTF.java` | 39KB | (暫不實作) | P3 | 字體反爬，極複雜，僅少數網站需要 |
| `RuleData.kt` | 1KB | (合併至 analyze_rule.dart) | P0 | 規則上下文數據介面 |
| `CustomUrl.kt` | 1KB | (合併至 analyze_url.dart) | P1 | 自訂 URL 處理 |

### 書源業務邏輯 (`legado/app/src/main/java/io/legado/app/model/webBook/`)

| Android 檔案 | 大小 | iOS 對應 | 說明 |
|-------------|------|---------|------|
| `WebBook.kt` | 15KB | `services/book_source_service.dart` | 統一入口：搜尋、書籍資訊、目錄、正文 |
| `BookList.kt` | 13KB | (整合至 book_source_service.dart) | 搜尋/發現結果列表解析 |
| `BookInfo.kt` | 7KB | (整合至 book_source_service.dart) | 書籍詳情頁解析 |
| `BookChapterList.kt` | 13KB | (整合至 book_source_service.dart) | 章節目錄解析(含翻頁 nextTocUrl) |
| `BookContent.kt` | 9KB | (整合至 book_source_service.dart) | 正文內容解析(含翻頁 nextContentUrl) |
| `SearchModel.kt` | 8KB | (需新建 `services/search_model.dart`) | 多源並發搜尋、結果聚合 |

### JS 擴展 (`legado/app/src/main/java/io/legado/app/help/`)

| Android 檔案 | 大小 | iOS 對應 | 說明 |
|-------------|------|---------|------|
| `JsExtensions.kt` | 33KB | (需新建 `engine/js/js_extensions.dart`) | 暴露 `java.xxx()` 給書源 JS。關鍵函式: `ajax()`, `connect()`, `base64Decode/Encode()`, `aesEncrypt/Decrypt()` 等 |
| `JsEncodeUtils.kt` | 15KB | (需新建 `engine/js/js_encode_utils.dart`) | AES/DES/RSA/Base64/MD5 加解密 |
| `ConcurrentRateLimiter.kt` | 5KB | (需新建 `core/services/rate_limiter.dart`) | 防封 IP 的速率控制器 |

### 資料實體 (`legado/app/src/main/java/io/legado/app/data/entities/`)
| Android 檔案 | iOS 對應 | 狀態 |
|-------------|---------|------|
| `BookSource.kt` + `rule/*.kt` | `models/book_source.dart` | ✅ 已完成 |
| `Book.kt` | `models/book.dart` | ✅ 已完成 |
| `BookChapter.kt` | `models/chapter.dart` | ✅ 已完成 |
| `SearchBook.kt` | `models/search_book.dart` | ✅ 已完成 |
| `ReplaceRule.kt` | `models/replace_rule.dart` | ✅ 已完成 |

---

## 🎯 實作順序（建議 Agent 依序完成）

### 第 1 步：確保專案可運行
```
1. cd reader/ios
2. flutter pub get
3. flutter analyze  (應只有 lint warnings，無 error)
4. flutter run      (在 Android 模擬器或連接設備上運行)
```

### 第 2 步：解析引擎（核心中的核心）
**按此順序實作，每完成一個就寫測試：**

1. **`analyze_by_json_path.dart`** — 翻譯 `AnalyzeByJSonPath.kt`(6KB)
   - 使用 `json_path` 套件
   - 實作 `getElements(rule)` 和 `getString(rule)`
   - 測試: 用 `$.store.book[*]` 格式測試 JSON 提取

2. **`analyze_by_css.dart`** — 翻譯 `AnalyzeByJSoup.kt`(18KB)
   - 使用 `html` 套件 (注意: Jsoup 的 API 和 Dart html package 差異很大)
   - 關鍵: 支援 `tag.class@attr` 格式 (Legado 自創語法，不是標準 CSS)
   - Legado CSS 語法: `div.bookList@tag.a!0@href` 表示「取 div.bookList 下所有 a 標籤的第一個的 href」
   - 支援特殊屬性: `text`, `textNodes`, `ownText`, `html`, `src`, `href`, `data-*`

3. **`analyze_by_xpath.dart`** — 翻譯 `AnalyzeByXPath.kt`(5KB)
   - 使用 `xpath_selector_html_parser`
   - 注意 `/@href` 尾綴的屬性提取需要自塗處理

4. **`analyze_by_regex.dart`** — 翻譯 `AnalyzeByRegex.kt`(2KB)
   - 支援 `##regex##replacement` 格式
   - 支援分組提取 `$1`, `$2`

5. **`rule_analyzer.dart`** (新建) — 翻譯 `RuleAnalyzer.kt`(15KB)
   - 規則字串切割引擎
   - 處理 `&&`, `||`, `%%`, `{{code}}`, `@put:{key:rule}`, `@get:{key}`

6. **`analyze_rule.dart`** — 翻譯 `AnalyzeRule.kt`(32KB)
   - 整合以上所有解析器
   - 根據前綴 `@css:`, `@json:`, `@xpath:`, `@js:` 分流
   - 處理 `&&`(合併), `||`(擇一), `%%`(格式化)
   - 實作 `@put/@get` 變數暫存
   - 實作 `{{javascript}}` 內嵌執行

7. **`analyze_url.dart`** — 翻譯 `AnalyzeUrl.kt`(29KB)
   - 解析 Legado URL 格式: `url, {"method":"POST","body":"...","headers":{...}}`
   - 支援 `{{key}}`, `{{page}}`, `{{pageSize}}` 變數替換
   - 支援 `webView: true` 標記偵測
   - 支援 charset 強制編碼

### 第 3 步：JS 引擎
1. **`js_engine.dart`** — 初始化 `flutter_js` runtime
2. **`js_extensions.dart`** (新建) — 最常用的 JS bridge 函式:
   - `java.ajax(url)` / `java.connect(url)` → Dio HTTP 請求
   - `java.base64Decode/Encode(str)`
   - `java.aesDecryptStr(data, key, iv)` / `java.aesEncryptStr(...)`
   - `java.md5Encode(str)` / `java.md5Encode16(str)`
   - `cookie.getCookie(url)` / `cookie.setCookie(url, cookie)`

### 第 4 步：書源業務服務
- **`book_source_service.dart`** — 翻譯 `WebBook.kt` + `BookList.kt` + `BookInfo.kt` + `BookChapterList.kt` + `BookContent.kt`
- 實作 `searchBooks()`, `getBookInfo()`, `getChapterList()`, `getContent()`, `exploreBooks()`

### 第 5 步：資料庫 DAO
- 建立 `core/database/dao/` 目錄
- 實作 `book_source_dao.dart` (書源 CRUD)
- 實作 `book_dao.dart` (書籍 CRUD)
- 實作 `chapter_dao.dart` (章節 CRUD + 正文快取)

### 第 6 步：UI 功能頁面
依序實作：
1. **書源管理頁** — 匯入 URL/剪貼簿、啟用/禁用、列表顯示
2. **搜尋頁** — 多源並發搜尋、結果聚合
3. **書架頁** — 書籍網格/列表、下拉更新
4. **閱讀器頁** — 正文顯示、字體/背景設定、上下滑動
5. **發現頁** — 探索分類、流式載入
6. **設定頁** — 功能串接

---

## ⚠️ 關鍵注意事項

### 1. Legado 自創的 CSS 語法（最容易踩坑）
Legado 的 CSS 規則 **不是標準 CSS 選擇器**，而是自創格式：
```
tag.class@attr              → 標準 CSS 選擇器 + 屬性提取
div.result@tag.a!0@href     → 取 div.result 下所有 a 標籤的第 0 個的 href
class.bookName@text         → 取 class="bookName" 的文字內容
```
翻譯 `AnalyzeByJSoup.kt` 時需要特別注意這個自創語法的解析，它在 `@` 符號處做切割。

### 2. JS 引擎的 java.xxx() 橋接
Android 書源 JS 中大量使用 `java.xxx()` 函式（如 `java.ajax(url)`, `java.base64Decode(str)`），這些在 iOS 上不存在。需要在 `flutter_js` 中注入全域 `java` 物件來模擬這些函式。

### 3. URL 格式的複雜性
Legado 的 URL 不是普通 URL，可能包含：
```
https://api.example.com/search?q={{key}}&p={{page}}, {
  "method": "POST",
  "body": "keyword={{key}}",
  "headers": {"User-Agent": "Mozilla/5.0"},
  "charset": "gbk",
  "webView": true
}
```
必須正確解析逗號後的 JSON 配置。

### 4. 多規則邏輯符號
```
rule1 && rule2    → 兩個結果合併（文字串接或列表合併）
rule1 || rule2    → rule1 失敗時 fallback 到 rule2
rule1 %% rule2    → 格式化（較少用）
```

### 5. 編碼問題
部分中文小說網站使用 GBK / GB2312 編碼而非 UTF-8，`AnalyzeUrl` 需支援 charset 強制編碼轉換。

---

## ✅ 已完成的部分

- [x] Flutter 專案建立 (`flutter create`)
- [x] Git 初始化 + 首次 commit
- [x] pubspec.yaml 全部依賴宣告
- [x] 5 個資料模型 (Book, BookSource, Chapter, SearchBook, ReplaceRule) — 含完整 JSON 序列化
- [x] SQLite 資料庫 Schema (6 個表)
- [x] App 主題 (Material 3 Light/Dark + 5 套閱讀主題)
- [x] App 入口 + 4-tab 底部導航
- [x] 6 個 UI 頁面骨架
- [x] 6 個解析引擎 stub

## ❌ 尚未完成的部分

- [ ] `flutter pub get` (依賴可能需要版本微調)
- [ ] 所有解析引擎的實際邏輯
- [ ] JS 引擎初始化 + bridge 函式
- [ ] 書源業務服務
- [ ] 資料庫 DAO 層
- [ ] 所有 UI 頁面邏輯
- [ ] 單元測試
- [ ] Codemagic CI/CD 配置

---

## 📊 Android 原始碼大小參考

供翻譯時評估工作量：

| 模組 | 檔案數 | 總大小 | 複雜度 |
|------|--------|--------|--------|
| `model/analyzeRule/` | 11 | ~150KB | 🔴 極高 |
| `model/webBook/` | 6 | ~65KB | 🟡 中高 |
| `help/JsExtensions.kt` | 1 | 33KB | 🔴 高 |
| `help/JsEncodeUtils.kt` | 1 | 15KB | 🟡 中 |
| `data/entities/` | 38 | ~200KB | 🟢 中 (大部分是 model) |
| `ui/book/read/` | ~40 | ~300KB | 🔴 極高 |
| `ui/main/bookshelf/` | ~15 | ~80KB | 🟡 中 |

---

## 🔗 相關文件

- 開發策略文檔 (更高層的決策分析): 查看 Antigravity brain 目錄中的 `ios_development_strategy.md`
- Android 和 iOS 功能差異分析: 查看之前對話 `c98e0e4e` 的 `feature_gap_analysis.md`
