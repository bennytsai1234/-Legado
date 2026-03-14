# 🏗️ 結構化迭代地圖 (Project Structure Iteration Map) v2

本文件以 Android (Legado) 目錄為基準，精確記錄每一個子功能的實作細節。

---

## 📊 模組迭代狀態與細節

| Android 目錄 | 核心功能點 (細節) | iOS/Flutter 實作進度 | 狀態 |
| :--- | :--- | :--- | :--- |
| **`ui/main`** | **書架搜尋**: 實作動態 AppBar 與關鍵字過濾 | `lib/features/bookshelf` | 🟢 100% |
| | **分組管理**: 支援書籍批量移動、分組 CRUD | `lib/features/bookshelf` | 🟢 100% |
| | **視圖切換**: 支援列表/網格(Grid)動態切換 | `lib/features/bookshelf` | 🟢 100% |
| **`ui/book/read`** | **自定義點擊**: 實作九宮格區域動作映射 | `lib/features/reader` | 🟢 100% |
| | **精細排版**: 實作首行縮排、兩端對齊(Justify) | `lib/features/reader/engine` | 🟢 98% |
| | **主題聯動**: 實作主題與排版參數(行高/字體)同步 | `lib/features/reader` | 🟢 100% |
| | **長按選單**: 實作複製、查詞、筆記、搜尋、分享 | `lib/features/reader` | 🟢 100% |
| **`ui/book/source`**| **專業調試**: 實作 HTTP 詳情、JSON 美化、日誌匯出 | `lib/features/source_manager` | 🟢 100% |
| | **批量校驗**: 實作並行測試、校驗詳情日誌、失效清理 | `lib/features/source_manager` | 🟢 100% |
| | **拖曳排序**: 實作 ReorderableListView 手動排序 | `lib/features/source_manager` | 🟢 100% |
| **`ui/login`** | **Cookie 捕捉**: 實作 HttpOnly Cookie 與 UA 同步 | `lib/features/source_manager` | 🟢 100% |
| **`ui/dict`** | **多標籤查詞**: 實作 TabLayout 樣式與規則複製貼上 | `lib/features/dict` | 🟢 100% |
| **`ui/font`** | **字體管理**: 實作網路下載、預覽文字大小調節 | `lib/features/settings` | 🟢 100% |
| **`ui/replace`** | **即時調試**: 實作編輯器內 Regex 替換效果預覽 | `lib/features/replace_rule` | 🟢 100% |
| **`ui/config`** | **進階 WebDAV**: 實作連通測試、子目錄/裝置名設定 | `lib/features/settings` | 🟢 100% |
| **`ui/welcome`** | **啟動規範**: 實作隱私協議檢查、動態歡迎圖 | `lib/features/welcome` | 🟢 100% |
| **`web`** | **HTTP API**: 實作書源/書架/進階 API | `lib/core/services/web_service`| 🟢 100% |
| | **資產託管**: 實作 static assets 伺服框架 | `lib/core/services/web_service`| 🟢 90% |
| | **WebSocket**: 實作實時搜尋/調試日誌推送 | `lib/core/services/web_service`| 🟢 100% |
| **`help`** | **3D 仿真翻頁**: 視覺陰影與捲曲細化 | `lib/features/reader/engine` | 🟡 60% |
| **`service`** | **鎖屏播放**: MediaControl 與通知欄交互 | `lib/core/services` | 🟡 40% |

---

## 🛠️ 最近完成的小功能記錄 (Small Features Log)
- [x] **[Reader]** 修正 `SimulationPageView` 的參數不相容與渲染漏洞。
- [x] **[Bookshelf]** 修復 `isBatchMode` 下的選取狀態同步問題。
- [x] **[Source]** 修復 `CheckSourceService` 的併發事件流回傳機制。
- [x] **[Login]** 強化 `WebViewCookieManager` 的平台層級 Cookie 持久化。
- [x] **[Theme]** 實作 `withValues(alpha: ...)` 替代已過時的 `withOpacity`。

---

## 🚀 待攻克的細節缺口
1.  **`web/WebSocket`**: 實作基於 `shelf_web_socket` 或原生的實時日誌推送。
2.  **`ui/book/read/simulation`**: 透過 `CustomPainter` 路徑優化，實現更具立體感的翻頁陰影。
3.  **`ui/config/backup`**: 實作 iOS 的「自動備份目錄監聽」（需結合 App Groups 或 File Provider）。

---
*地圖版本: v2.0 | 建立日期: 2026-03-14 | 由 AI Agent 完成細節校驗後產出*
