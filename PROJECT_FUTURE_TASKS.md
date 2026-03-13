# 專案未來開發任務與功能補全報告 (Project Future Roadmap & Stub Audit)

## 1. 核心斷層 (Logic Gaps)
針對核心邏輯中被 `// ...` 跳過或簡化的部分進行盤查：

*   **解析引擎 - 編碼檢測缺失 (`lib/core/engine/analyze_url.dart`)**:
    *   **現狀**: 在 `getResponseBody` 方法中，當字元編碼 (`charset`) 未知時，目前略過了對 `content-type` 的主動檢查 (`// ... (We skip content-type check for now, simplified)`)。
    *   **影響**: 對於部分未在標頭明確指定 UTF-8 的舊式書源（如 GBK/GB2312 網頁），可能導致抓取內容出現亂碼，影響資料解析的正確性。
*   **主題定義佔位 (`lib/shared/theme/app_theme.dart`)**:
    *   **現狀**: 類別定義中存在 `// ... (保留原有的色彩與主題定義)`。
    *   **影響**: 雖然目前已有基礎配色，但部分從 Android 遷移過來的細節配置（如特定組件的陰影、圓角等）可能尚未完全同步，導致 UI 在複雜情境下不夠精緻。
*   **閱讀核心 - 功能跳轉缺失 (`lib/features/reader/auto_read_dialog.dart`)**:
    *   **現狀**: 存在 `// TODO: 跳轉至翻頁動畫設定`。
    *   **影響**: 使用者在自動閱讀設定介面中無法直接進入動畫調整，操作路徑中斷。

## 2. 未實作清單 (Stub List)
列出目前程式碼中存在的實作佔位與待處理標記：

*   **日誌提示反饋 (`lib/core/services/app_log_service.dart`)**:
    *   **位置**: L34, `// TODO: Implement toast injection if needed`。
    *   **說明**: 目前 `AppLog.put` 僅能將日誌寫入內存與控制台，尚未實現將錯誤訊息直接以 Toast 或 Snackbar 彈出給使用者，這在進行遠端調試時會造成不便。
*   **動畫常量映射 (`lib/core/constant/page_anim.dart`)**:
    *   **位置**: L5, `AI_PORT: GAP-CONST-05`。
    *   **說明**: 部分翻頁動畫的數值僅為初步移植，尚未根據 Flutter 的 `PageController` 或 `CustomPainter` 進行流暢度優化。

## 3. 移植缺失 (Porting Gaps)
標記為 `AI_PORT` 但仍需針對 Flutter/iOS 環境進行最佳化的區塊：

*   **全域日誌持有人 (`lib/core/services/app_log_service.dart`)**:
    *   **標記**: `AI_PORT: derived from AppLog.kt`。
    *   **優化建議**: Android 版可能依賴靜態內部類，在 Flutter 中需注意 `Queue` 的內存管理，建議增加日誌持久化到檔案的機制，以應對 iOS 嚴格的後台進程限制。
*   **書籍類型定義 (`lib/core/constant/book_type.dart`)**:
    *   **標記**: `AI_PORT: GAP-CONST-02/03`。
    *   **優化建議**: 確認 `BookType` 的整數值與資料庫中既有的 Android 資料完全相容，避免在數據同步後出現類型識別錯誤。

## 4. 完善優先級建議

根據「資料抓取安全」、「持久化完整性」、「閱讀體驗一致性」三原則排定優先級：

### P0 - 最高優先級 (立即處理)
*   **資料抓取安全**: 補全 `analyze_url.dart` 的 `content-type` 偵測。這是所有網路請求的基礎，編碼識別錯誤會導致整個解析引擎失效。
*   **持久化完整性**: 壓力測試 `app_database.dart` 的初始化邏輯。目前雖然有處理資料庫鎖定問題，但在高頻併發讀寫（如背景批量下載章節時）的穩定性仍需驗證。

### P1 - 中優先級 (功能補全)
*   **閱讀體驗一致性**: 完善 `app_theme.dart` 與 `auto_read_dialog.dart`。確保 iOS 使用者的翻頁體驗、色彩配置與 Android 原版保持高度一致，減少遷移後的違和感。
*   **日誌提示注入**: 實作 `AppLog` 的 UI 反饋機制，這對於後續 Bug 追蹤與用戶反饋至關重要。

### P2 - 低優先級 (細節優化)
*   **常量重構**: 檢核所有 `AI_PORT` 標記的常量，將硬編碼數值根據 iOS 設備的分辨率與刷新率進行細微調整。
