# 佔位代碼與待實作功能審查報告 (Placeholder & Unimplemented Features Audit Report)

本報告列出了 iOS 專案中目前仍為佔位符 (Placeholder) 或 尚未完整實作 (Partially Implemented) 的部分，供後續開發進度追蹤參考。

## 📊 審查摘要
- **主要發現**：多個核心服務（如 `WebService`, `IntentHandlerService`, `DebugPage`）存在核心功能的缺失。
- **風險等級**：
    - 🔴 **高**：核心數據流或功能流程中斷。
    - 🟡 **中**：功能可用但缺乏細節或與 Android 版本不一致。
    - ⚪ **低**：UI 佔位符或日誌顯示。

---

## 🔍 詳細列表

### 1. 核心服務 (Core Services)

| 檔案路徑 | 行號 | 類型 | 描述 | 風險 |
| --- | --- | --- | --- | --- |
| `lib/core/services/web_service.dart` | 352 | TODO | `handleAddLocalBook` 函數僅完成檔案上傳與暫存，**尚未實作**將書籍匯入至 `BookshelfProvider` 或 `BookDao` 的邏輯。 | 🔴 高 |
| `lib/features/association/intent_handler_service.dart` | 223 | TODO | 外部連結匯入 `httpTts` 時，**尚未實作** `TtsProvider` 的匯入對接。 | 🟡 中 |
| `lib/features/association/intent_handler_service.dart` | 228 | TODO | 外部連結匯入主題時，**尚未實作** `ThemeProvider` 的匯入對接。 | 🟡 中 |
| `lib/core/services/backstage_webview.dart` | 39 | Placeholder | 背景 WebView 請求邏輯目前僅為佔位。 | 🟡 中 |

### 2. 功能頁面 (Feature Pages)

| 檔案路徑 | 行號 | 類型 | 描述 | 風險 |
| --- | --- | --- | --- | --- |
| `lib/features/debug/debug_page.dart` | 52 | TODO | **偵錯流程尚未實作**。目前僅模擬日誌輸出，無法進行實際的書源規則偵錯。 | 🔴 高 |
| `lib/features/reader/auto_read_dialog.dart` | 79 | TODO | 自動翻頁對話框中，「跳轉至翻頁動畫設定」的功能尚未實作。 | 🟡 中 |

### 3. UI 佔位符 (UI Placeholders - 低風險)
以下部分為正常開發中的 UI 提示或載入動畫，不影響核心邏輯，但屬佔位性質：
- `lib/features/search/search_page.dart` (L190): `CachedNetworkImage` 載入佔位。
- `lib/features/rss/rss_article_page.dart` (L149): RSS 文章圖片佔位元件 `_buildPlaceholder()`。
- `lib/features/book_detail/book_detail_page.dart` (L185): 書籍詳情頁封面佔位元件 `_buildCoverPlaceholder()`。
- `lib/features/bookshelf/bookshelf_page.dart` (L352): 書架首頁封面佔位元件 `_buildCoverPlaceholder(book)`。

---

## 💡 建議後續動作
1. **優先修復**：`WebService` 的書籍匯入邏輯，這是讓「Web 傳書」功能完整的關鍵。
2. **功能補齊**：`DebugPage` 的實際規律分析調用。
3. **系統對接**：`IntentHandlerService` 與 `TtsProvider`/`ThemeProvider` 的整合。

報告生成時間：2026-03-13
鑑定人員：Antigravity Agent
