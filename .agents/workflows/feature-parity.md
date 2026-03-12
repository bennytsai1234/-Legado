# 🔄 增量式代碼審計 SOP v3：外科手術式精確對齊 (完整版)

本工作流程旨在確保 Legado (Android) 遷移至 Reader (iOS) 的過程中，所有功能與邏輯均能達到原始碼級別的完全對齊。

---

## 階段一：建立全局地圖 (Global Mapping Phase)
在開始具體審計前，需先理清兩個專案之間的物理檔案對應關係。

1.  **清單掃描**：
    - 列出 Android (Legado) 的完整 `ui/`, `model/`, `help/` 目錄結構。
    - 列出 iOS (Reader) 的完整 `lib/features/`, `lib/core/` 目錄結構。
2.  **建立 `COMPREHENSIVE_FEATURE_MAPPING.md`**：
    - 定義「功能責任區」：明確標註 Android 的 `Activity/ViewModel/Help` 對應 iOS 的 `Page/Provider/Service/DAO`。

---

## 階段二：模組專項審計 (Incremental Audit Loop)
針對地圖中的 **[資料夾 X]**，執行外科手術式的深度掃描：

1.  **Android 端「互動與邏輯」提取**：
    - 讀取 Kotlin 原始碼與相關的 XML 佈局檔案。
    - 提取 UI 進入點、核心演算（正則、公式）、以及邊際狀態處理。
2.  **iOS 端「直接閱讀與驗證」**：
    - 直接讀取對應的 Dart 檔案，與 Android 的特徵清單逐條比對。
    - 標註 `Matched` (一致), `Equivalent` (等效), `Logic Gap` (缺失)。
3.  **單一文件增量寫入**：
    - 將比對結果附加到 `FEATURE_AUDIT_LOG.md`。
    - 格式：`[邏輯點] + [Android 路徑:行號] + [iOS 路徑:行號] + [狀態描述]`。

---

## 階段三：總表同步與導航更新 (Aggregation Phase)
1.  **更新完成度**：根據審計結果更新 `FEATURE_AUDIT_v2.md` 中的百分比。
2.  **提取「邏輯缺口」**：將發現的 `Logic Gap` 轉化為後續開發任務清單。
3.  **備份 (Commit)**：每完成一個模組，立即執行 Git Commit。
