# 🤖 Agent 交接文檔 — Legado iOS Reader

> **最後更新**: 2026-03-10  
> **目標**: 將 Android Legado 閱讀器完整移植到 iOS（使用 Flutter）  
> **當前狀態**: 核心閱讀路徑已通，整體完成度約 **45%**

---

## 📍 專案位置

| 專案 | 路徑 |
|------|------|
| **iOS Flutter 專案** | `c:\Users\benny\Desktop\Folder\Project\reader\ios\` |
| **Android 原始碼（參考）** | `c:\Users\benny\Desktop\Folder\Project\reader\legado\` |
| Android 核心代碼根目錄 | `legado\app\src\main\java\io\legado\app\` |

---

## 📐 iOS 專案架構

```
ios/lib/
├── main.dart                    ← 入口 (MultiProvider)
├── core/
│   ├── engine/
│   │   ├── analyze_rule.dart    ← 規則總控 (347行)
│   │   ├── analyze_url.dart     ← URL 引擎 (174行)
│   │   ├── rule_analyzer.dart   ← 規則切割器 (352行)
│   │   ├── js/
│   │   │   ├── js_engine.dart         ← QuickJS 包裝 (53行)
│   │   │   ├── js_extensions.dart     ← java.* 橋接 (102行)
│   │   │   └── js_encode_utils.dart   ← 加密工具 (111行)
│   │   └── parsers/
│   │       ├── analyze_by_css.dart         (CSS, 12KB)
│   │       ├── analyze_by_json_path.dart   (JsonPath, 4KB)
│   │       ├── analyze_by_xpath.dart       (XPath, 4KB)
│   │       └── analyze_by_regex.dart       (Regex, 3KB)
│   ├── models/                  ← 28 個數據模型
│   ├── database/
│   │   ├── app_database.dart    ← SQLite (6 張表)
│   │   └── dao/                 ← 5 個 DAO
│   └── services/
│       ├── book_source_service.dart   (185行)
│       └── rate_limiter.dart          (並發控制)
├── features/                    ← 7 個頁面 (每個含 page + provider)
│   ├── bookshelf/  explore/  search/  book_detail/
│   ├── reader/  source_manager/  settings/
└── shared/theme/
```

---

## 🔧 開發約定

- **修改方式**: 禁止 `write_file` 覆寫 Git 追蹤檔案，僅用 `replace`
- **備份**: 修改後立即 `git add <file> ; git commit -m "backup: ..."`
- **對話語言**: 繁體中文 | **代碼**: 英文 | **Commit**: Conventional Commits 英文
- **狀態管理**: Provider + ChangeNotifier
- **網路**: Dio | **資料庫**: sqflite | **JS 引擎**: flutter_js (QuickJS)

---

## 📊 待實作功能清單 (含 Android 對照檔案)

以下每個任務都列出：**要做什麼**、**Android 原始碼在哪**、**iOS 要建/改哪個檔案**、**具體要移植什麼**。

Android 路徑前綴統一為 `legado\app\src\main\java\io\legado\app\` (以下簡稱 `A:`)  
iOS 路徑前綴統一為 `ios\lib\` (以下簡稱 `I:`)

---

### 🔴 任務群 A：JS 橋接補全 (最高優先級)

> 這直接決定多少書源能跑通。Android 的 `JsExtensions.kt` 有 83 個方法，iOS 僅實作了 ~15 個。

#### A1. JsExtensions 網路類方法

| 功能 | Android 方法 (A:`help/JsExtensions.kt`) | iOS 目標 (I:`core/engine/js/js_extensions.dart`) | 實作說明 |
|------|----------------------------------------|-----------------------------------------------|---------|
| 並發 GET | `ajaxAll(urlList: Array<String>)` L110-124 | `java.ajaxAll` | 用 `Future.wait()` + Dio 並發 |
| 帶 Header GET | `get(urlStr, headers)` L375-394 | `java.get` | Dio + Options(headers) |
| HEAD 請求 | `head(urlStr, headers)` L396-415 | `java.head` | Dio HEAD |
| POST 請求 | `post(urlStr, body, headers)` L417-437 | `java.post` | Dio POST |
| WebView 渲染 | `webView(html, url, js)` L163-183 | `java.webView` | webview_flutter 離屏載入 |
| WebView 取源碼 | `webViewGetSource(html, url, js, sourceRegex)` L185-202 | `java.webViewGetSource` | 同上 |
| 連接資訊 | `connect(urlStr, header)` L145-161 | 改進現有 `java.connect` | 增加 header 參數 |

#### A2. JsExtensions Cookie/快取類

| 功能 | Android 方法 | iOS 目標 | 實作說明 |
|------|-------------|---------|---------|
| 讀取 Cookie | `getCookie(tag)` L302-307 | `java.getCookie` | 需先建 CookieStore (見 B1) |
| 讀取指定 Cookie | `getCookie(tag, key)` L309-315 | `java.getCookie` | 解析 Cookie 字串取特定 key |
| 載入外部 JS | `importScript(path)` L261-271 | `java.importScript` | URL→下載→evaluate |
| 快取檔案 | `cacheFile(url, saveTime)` L282-300 | `java.cacheFile` | 本地檔案 + 過期時間戳 |
| 下載檔案 | `downloadFile(url)` L317-344 | `java.downloadFile` | Dio 下載 + 寫入本地 |

#### A3. JsExtensions 編碼/工具類

| 功能 | Android 方法 | iOS 目標 | 實作說明 |
|------|-------------|---------|---------|
| 字串轉位元組 | `strToBytes(str, charset)` L439-446 | `java.strToBytes` | `dart:convert` encoding |
| 位元組轉字串 | `bytesToStr(bytes, charset)` L448-455 | `java.bytesToStr` | 同上 |
| Base64 帶 charset | `base64Decode(str, charset)` L464-466 | 改進 `java.base64Decode` | 增加 charset 參數 |
| HTML 格式化 | `htmlFormat(str)` L543-545 | `java.htmlFormat` | 用 `html` 套件清理 |
| 繁→簡 | `t2s(text)` L547-549 | `java.t2s` | 考慮用 opencc 或查表法 |
| 簡→繁 | `s2t(text)` L551-553 | `java.s2t` | 同上 |
| 取 WebView UA | `getWebViewUA()` L555-557 | `java.getWebViewUA` | 返回固定 UA 字串 |
| 讀本地檔 | `readFile(path)` / `readTxtFile(path)` L581-604 | `java.readFile` | `dart:io` File.readAsString |
| 解壓 ZIP | `unzipFile(zipPath)` L614-621 | `java.unzipFile` | `archive` 套件 |
| 章節數轉數字 | `toNumChapter(s)` L913-924 | `java.toNumChapter` | 中文數字轉阿拉伯 |
| 提示 | `toast(msg)` / `log(msg)` L935-961 | `java.toast`/`java.log` | print / SnackBar |

#### A4. JsExtensions 字體反爬 (進階)

| 功能 | Android 方法 | iOS 目標 | 實作說明 |
|------|-------------|---------|---------|
| 解析 TTF 字體 | `queryTTF(data, useCache)` L807-855 | `java.queryTTF` | 需建立 TTF 解析器 |
| Base64 TTF | `queryBase64TTF(data)` L795-805 | `java.queryBase64TTF` | base64 解碼後調 queryTTF |
| 字體替換 | `replaceFont(text, errorTTF, correctTTF, filter)` L861-910 | `java.replaceFont` | 用 cmap 表做字符映射 |
| **Android 參考** | `A:model/analyzeRule/QueryTTF.java` (39KB) | 建 `I:core/engine/js/query_ttf.dart` | 這是最複雜的單一移植任務 |

#### A5. JsEncodeUtils 加密方法補全

| 功能 | Android (A:`help/JsEncodeUtils.kt`) | iOS (I:`core/engine/js/js_encode_utils.dart`) | 說明 |
|------|-------------------------------------|----------------------------------------------|------|
| AES 解碼→ByteArray | `aesDecodeToByteArray(str,key,transformation,iv)` L91-107 | 擴展 `symmetricCrypto` | 支援更多參數格式 |
| AES 解碼→String | `aesDecodeToString(...)` L109-124 | 同上 | |
| AES Base64→解碼 | `aesBase64DecodeToString(...)` L171-186 | 新增 | 先 base64 解碼再 AES |
| AES 加密→Base64 | `aesEncodeToBase64String(...)` L239-254 | 新增 | |
| AES 參數 Base64 | `aesDecodeArgsBase64Str(data,key,mode,padding,iv)` L126-152 | 新增 | key/iv 本身也是 Base64 |
| DES 系列 | `desDecodeToString(...)` 等 | 新增 | 目前 DES throw Unimplemented |
| 3DES 系列 | `tripleDesDecodeToString(...)` 等 | 新增 | |
| 非對稱加密 | `createAsymmetricCrypto(transformation)` L76-81 | 新增 | RSA |
| HMAC | 多個 HMAC 方法 | 新增 | 用 `crypto` 套件 |
| 簽名 | `createSign(algorithm)` L83-88 | 新增 | |

---

### 🔴 任務群 B：核心引擎強化

#### B1. Cookie 管理系統 (全新)

| 對照 | Android 檔案 | iOS 目標 |
|------|-------------|---------|
| Cookie 儲存 | `A:help/http/CookieStore.kt` (4KB) | 建 `I:core/services/cookie_store.dart` |
| Cookie 管理 | `A:help/http/CookieManager.kt` (6KB) | 整合到上面 |
| Cookie DAO | `A:data/dao/CookieDao.kt` (1KB) | 建 `I:core/database/dao/cookie_dao.dart` |
| Cookie 實體 | `A:data/entities/Cookie.kt` (已有) | `I:core/models/cookie.dart` (已有) |

**要做的事**:
1. 建立 `CookieStore` 類，用 sqflite 存取 domain→cookie 映射
2. 在 `AnalyzeUrl.getResponseBody()` 發請求前注入 Cookie
3. 在請求完成後保存 Set-Cookie
4. 在 `JsExtensions` 中暴露 `getCookie`/`setCookie`

#### B2. AnalyzeUrl 強化

| 缺失功能 | Android 位置 (A:`model/analyzeRule/AnalyzeUrl.kt`) | iOS 修改位置 | 說明 |
|---------|--------------------------------------------------|-------------|------|
| `<js>...</js>` 標籤 | `analyzeJs()` L150-176 | 改 `I:core/engine/analyze_url.dart` `_analyzeJs()` | 目前只支援 `@js:` |
| 表單參數解析 | `analyzeFields()` L273-281 | 新增方法 | 解析 `key=value&key2=value2` |
| URL 編碼 | `encodeParams()` L287-329 | 新增方法 | RFC3986 百分號編碼 |
| 字元集偵測 | `EncodingDetect.getHtmlEncode()` | 新增 | GBK/GB2312 偵測 + 轉碼 |
| Cookie 注入 | `setCookie()` L604-630 | 整合 CookieStore | 請求前注入 |
| Cookie 保存 | `saveCookie()` L632-646 | 整合 CookieStore | 請求後保存 |
| Dio 單例 | `okHttpClient` (全域) | 建 `I:core/services/http_client.dart` | 目前每次 new Dio() |
| 重定向處理 | `setRedirectUrl()` | 新增 | 調整 baseUrl |
| WebView 模式 | `getStrResponseAwait()` L397-473 | 用 webview_flutter | useWebView=true 時觸發 |

#### B3. AnalyzeRule 強化

| 缺失功能 | Android 位置 (A:`model/analyzeRule/AnalyzeRule.kt`) | iOS 修改位置 | 說明 |
|---------|--------------------------------------------------|-------------|------|
| 重定向 URL | `setRedirectUrl()` L105-115 | 改 `I:core/engine/analyze_rule.dart` | 更新 baseUrl |
| `@put:{}` 解析 | `splitPutRule()` L405-431 | 新增方法 | 存取變數到 RuleData |
| HTML 反轉義 | `StringEscapeUtils.unescapeHtml4()` | 新增 | 用 `html_unescape` 套件 |
| JS 編譯快取 | `compileScriptCache()` L806-810 | 新增 | 避免重複解析 JS |
| Regex 編譯快取 | `compileRegexCache()` L462-470 | 新增 | `RegExp` 物件重用 |
| 單元素獲取 | `getElement()` L329-361 | 新增 | 返回單一物件而非列表 |
| Chapter 上下文 | `setChapter()` L843-845 | 新增 | 目錄翻頁需要 |
| SourceRule.splitRegex | `splitRegex()` L624-654 | 新增 | `$1` `$2` 正則組引用 |
| NativeObject 處理 | getString 中的 Rhino NativeObject | 調整 | QuickJS 返回值型別處理 |

#### B4. SharedJsScope (跨腳本變數共用)

| 對照 | Android 檔案 | iOS 目標 |
|------|-------------|---------|
| 共用作用域 | `A:model/SharedJsScope.kt` (87行) | 建 `I:core/engine/js/shared_js_scope.dart` |

**要做的事**: 實作一個 LRU 快取，用 `jsLib` 的 MD5 作為 key，快取已執行過的 JS 作用域。支援 URL 形式的 jsLib (下載→快取→evaluate)。

---

### 🟡 任務群 C：BookSourceService 增強

| 缺失功能 | Android 位置 | iOS 修改位置 | 說明 |
|---------|-------------|-------------|------|
| 正文翻頁 | `A:model/webBook/BookContent.kt` L34-156 `nextChapterUrl` | 改 `I:core/services/book_source_service.dart` `getContent()` | 正文也需要 nextUrl 翻頁 |
| 精確搜尋 | `A:model/webBook/WebBook.kt` `preciseSearch()` L358-400 | 新增方法 | 按書名+作者精確匹配 |
| 重定向檢測 | `A:model/webBook/WebBook.kt` `checkRedirect()` L402-413 | 新增方法 | 檢查 302 跳轉 |
| 內容處理器 | `A:help/book/ContentProcessor.kt` (207行) | 建 `I:core/services/content_processor.dart` | 替換規則+繁簡轉換+去重複標題 |
| 書源登入 | `A:help/source/SourceVerificationHelp.kt` (4KB) | 建 `I:core/services/source_login.dart` | loginUrl/loginUi 登入流程 |

---

### 🟡 任務群 D：DAO 補全

| DAO | Android 檔案 (A:`data/dao/`) | iOS 目標 (I:`core/database/dao/`) | 優先級 |
|-----|------------------------------|--------------------------------|--------|
| CookieDao | `CookieDao.kt` (1KB) | 建 `cookie_dao.dart` | P0 |
| BookmarkDao | `BookmarkDao.kt` (2KB) | 建 `bookmark_dao.dart` | P0 |
| CacheDao | `CacheDao.kt` (1KB) | 建 `cache_dao.dart` | P0 |
| ReadRecordDao | `ReadRecordDao.kt` (2KB) | 建 `read_record_dao.dart` | P1 |
| BookGroupDao | `BookGroupDao.kt` (3KB) | 建 `book_group_dao.dart` | P1 |
| RssSourceDao | `RssSourceDao.kt` (5KB) | 建 `rss_source_dao.dart` | P2 |
| RssArticleDao | `RssArticleDao.kt` (1KB) | 建 `rss_article_dao.dart` | P2 |
| RssStarDao | `RssStarDao.kt` (1KB) | 建 `rss_star_dao.dart` | P2 |
| SearchBookDao | `SearchBookDao.kt` (3KB) | 建 `search_book_dao.dart` | P2 |
| DictRuleDao | `DictRuleDao.kt` (1KB) | 建 `dict_rule_dao.dart` | P3 |
| HttpTTSDao | `HttpTTSDao.kt` (1KB) | 建 `http_tts_dao.dart` | P3 |
| RuleSubDao | `RuleSubDao.kt` (1KB) | 建 `rule_sub_dao.dart` | P3 |
| TxtTocRuleDao | `TxtTocRuleDao.kt` (1KB) | 建 `txt_toc_rule_dao.dart` | P3 |

同時需為新 DAO 在 `app_database.dart` 的 `_onCreate()` 中增加對應的 CREATE TABLE。

---

### 🟡 任務群 E：閱讀器排版引擎

| 功能 | Android 參考 | iOS 目標 | 說明 |
|------|-------------|---------|------|
| 文字測量+分頁 | `A:ui/book/read/page/provider/ChapterProvider.kt` | 建 `I:features/reader/engine/chapter_provider.dart` | TextPainter 測量→分頁 |
| 頁面數據模型 | `A:ui/book/read/page/entities/TextPage.kt` + `TextLine.kt` | 建 `I:features/reader/engine/text_page.dart` | |
| 翻頁容器 | `A:ui/book/read/page/PageView.kt` (17KB) | 建 `I:features/reader/engine/page_view_widget.dart` | PageView + GestureDetector |
| 覆蓋翻頁 | `A:ui/book/read/page/delegate/CoverPageDelegate.kt` | 建 `I:features/reader/engine/delegates/cover_delegate.dart` | |
| 滑動翻頁 | `A:ui/book/read/page/delegate/SlidePageDelegate.kt` | 建 `I:features/reader/engine/delegates/slide_delegate.dart` | |
| 仿真翻頁 | `A:ui/book/read/page/delegate/SimulationPageDelegate.kt` | 建 `I:features/reader/engine/delegates/curl_delegate.dart` | 最複雜，可用套件 |
| 滾動閱讀 | `A:ui/book/read/page/delegate/ScrollPageDelegate.kt` | 建 `I:features/reader/engine/delegates/scroll_delegate.dart` | |
| 閱讀狀態管理 | `A:model/ReadBook.kt` (1055行, 37KB) | 大幅改進 `I:features/reader/reader_provider.dart` | 前後章預載、進度追蹤 |

---

### 🟢 任務群 F：系統服務整合

| 功能 | Android 參考 | iOS 目標 | 建議套件 |
|------|-------------|---------|---------|
| TTS 朗讀 | `A:service/TTSReadAloudService.kt` (9KB) | 建 `I:core/services/tts_service.dart` | `flutter_tts` |
| HTTP TTS | `A:service/HttpReadAloudService.kt` (23KB) | 建 `I:core/services/http_tts_service.dart` | `just_audio` |
| WebDAV 備份 | `A:help/AppWebDav.kt` (13KB) | 建 `I:core/services/webdav_service.dart` | `webdav_client` |
| 離線下載 | `A:service/CacheBookService.kt` (7KB) + `A:model/CacheBook.kt` (16KB) | 建 `I:core/services/download_service.dart` | Dio + Isolate |
| 書源校驗 | `A:service/CheckSourceService.kt` (10KB) | 建 `I:core/services/check_source_service.dart` | |
| 備份還原 | `A:help/storage/Backup.kt` (12KB) + `Restore.kt` (13KB) | 建 `I:core/services/backup_service.dart` | |
| 閱讀設定 | `A:help/config/ReadBookConfig.kt` (26KB) + `AppConfig.kt` (27KB) | 建 `I:core/services/app_config.dart` | shared_preferences |

---

### ⚪ 任務群 G：進階功能 (低優先)

| 功能 | Android 參考目錄 | iOS 目標目錄 | 建議套件 |
|------|----------------|-------------|---------|
| 本地 EPUB | `A:model/localBook/EpubFile.kt` (17KB) | 建 `I:core/local_book/epub_parser.dart` | `epubx` |
| 本地 TXT | `A:model/localBook/TextFile.kt` (21KB) | 建 `I:core/local_book/txt_parser.dart` | 自建 (正則切章) |
| RSS 模組 | `A:model/rss/` (3 檔) + `A:ui/rss/` (30 檔) | 建 `I:features/rss/` | |
| 漫畫模式 | `A:ui/book/manga/` (21 檔) + `A:model/ReadManga.kt` | 建 `I:features/manga/` | |
| 有聲書 | `A:model/AudioPlay.kt` + `A:service/AudioPlayService.kt` | 建 `I:features/audio/` | `just_audio` |
| 替換規則 UI | `A:ui/replace/` (6 檔) | 建 `I:features/replace_rule/` | |
| 書籍匯入 | `A:ui/book/import/` (13 檔) | 建 `I:features/import/` | |

---

## ⚠️ 已知技術風險

1. **flutter_js (QuickJS) 相容性**: 部分書源的 JS 依賴 Rhino 的 Java 互操作。所有 `java.*` 呼叫必須透過橋接模擬。
2. **GBK 編碼**: Dart 原生不支援 GBK，需要 `gbk_codec` 或 `charset_converter` 套件。
3. **iOS 背景執行限制**: TTS、下載等需要在 `Info.plist` 宣告 `UIBackgroundModes`。
4. **QueryTTF (字體反爬)**: 這是 Android 版裡 39KB 的 Java 檔案，移植工作量大但重要。
5. **Dio 實例管理**: 目前每次請求 new Dio()，需改為全域單例避免連線池浪費。

---

## ⚡ 常用指令

```powershell
# 靜態分析
cd c:\Users\benny\Desktop\Folder\Project\reader\ios ; dart analyze lib/

# 執行測試
cd c:\Users\benny\Desktop\Folder\Project\reader\ios ; flutter test

# 運行 App
cd c:\Users\benny\Desktop\Folder\Project\reader\ios ; flutter run
```
