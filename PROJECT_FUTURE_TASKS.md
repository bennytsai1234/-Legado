# 專案開發任務與進度報告 (Project Roadmap & Task Audit) - 2026-03-14 更新

本文件已根據 2026-03-14 的源碼掃描結果進行更新，標記為「✅」的項目代表已完成或已補齊核心邏輯。

---

## 1. 核心邏輯對位現狀 (Logic Gap Audit)

*   **✅ 解析引擎 - 編碼檢測補全 (`analyze_url.dart`)**: 
    *   **現狀**: 已實作 `getResponseBody` 內的 `content-type` 偵測與 `gbk/utf8` 自動切換。
    *   **結果**: 支援 GBK 編碼書源，亂碼風險已降至最低。
*   **✅ 閱讀主題數據模型 (`app_theme.dart`)**:
    *   **現狀**: `ReadingTheme` 已完整定義超過 10 項排版屬性，並支援 JSON 文件持久化。
    *   **待優化**: 精細化的 UI 組件樣式（如特定陰影、圓角）仍可進一步對標 Android。
*   **❌ 閱讀核心 - 功能跳轉缺失 (`lib/features/reader/auto_read_dialog.dart`)**:
    *   **現狀**: 存在 `// TODO: 跳轉至翻頁動畫設定`。
    *   **影響**: 自動閱讀介面目前無法直接連動翻頁模式設定，路徑尚不流暢。

## 2. 工具與服務狀態 (Service & Stub Audit)

*   **✅ 日誌提示與注入 (`lib/core/services/app_log_service.dart`)**:
    *   **現狀**: 已實作 `toastStream` 廣播機制，核心 `put` 方法支援 `toast: true` 觸發。
    *   **待完成**: 在全局 Scaffold 層級增加一個 Listener 來消費此流並彈出 Snackbar。
*   **🟡 動畫常量與優化 (`lib/core/constant/page_anim.dart`)**:
    *   **說明**: 雖然定義已存在，但仍維持 `AI_PORT` 標記。
    *   **下一步**: 根據 Flutter 渲染特性調整 3D 仿真動畫的曲線參數。

---

## 3. 剩餘優先級任務 (Updated Priority)

### P0 - 立即處理 (Critical)
1.  **日誌 UI 消費者實作**: 既然 `AppLog` 的發送機制已好，應在 `main.dart` 或 `BasePage` 實作 Snackbar 的自動彈出，確保錯誤能被發現。

### P1 - 功能優化 (Enhancement)
1.  **連動翻頁設定**: 修復 `auto_read_dialog.dart` 中的 TODO，打通設定跳轉路徑。
2.  **內容預處理強化**: `content_processor.dart` 增加對重複標題的自動偵測（對位 Android Regex）。

### P2 - 技術債 (Refactor)
1.  **移除所有舊有的 `AI_PORT` 標記**: 當對位邏輯驗證穩定後，將這些歷史標記移除或轉化為正式註解。
2.  **常量檢核**: 完成 `book_type.dart` 等常量的數據一致性校驗。

---
*審核狀態: 源碼同步模式 - 2026-03-14*
