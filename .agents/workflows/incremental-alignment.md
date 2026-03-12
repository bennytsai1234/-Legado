# 🔄 增量式代碼對齊流程 (Incremental Alignment Pipeline) v3

本工作流程旨在採用「資料夾增量」方式，將穩定的 Android (Legado) 邏輯精確遷移至 iOS (Reader)，並確保語義級別的對齊。

---

## 階段一：建立全量地圖 (Global Mapping Phase)
在開始具體審計前，需先理清兩個專案之間的「邏輯責任區」。

1.  **全量結構掃描**：
    - 列出 Android (Legado) 所有的 Activity, ViewModel, Help, Data 類別。
    - 列出 iOS (Reader) 當前的所有 Page, Provider, Service, DAO 類別。
2.  **建立全量映射表 (`COMPREHENSIVE_FEATURE_MAPPING.md`)**：
    - **對應關係**：明確標註 Android 的「功能大腦（ViewModel/Help）」與 iOS 的「對應腦區（Provider/Service）」。
    - **邏輯錨點**：不限於檔案名，而是定義功能責任（如：換源演算法、WebDav 同步邏輯）。

---

## 階段二：單元遞增審計 (Module Loop)
按照資料夾逐個進行，採用「語義比對」策略以應對命名差異。

1.  **Android 邏輯與互動提取**：
    - 讀取 Kotlin 與 XML 佈局。
    - **提取重點**：識別所有影響 UI 顯示與資料處理的 **「判定分支 (if/else)」** 與 **「核心演算」**。
2.  **iOS 語義核對與驗證**：
    - **精確閱讀**：根據映射表，直接開啟 iOS 對應檔案。
    - **對齊校核**：忽略命名差異（如變數名不同），專注於「這段邏輯在 iOS 裡有沒有做？」、「處理流程是否一致？」。
    - **標註標準**：`Matched` (一致), `Equivalent` (語義對等但寫法不同), `Logic Gap` (完全缺失)。
3.  **單一文件增量追加**：
    - 將核對結果追加至 `FEATURE_AUDIT_LOG.md`。
    - 每次完成一個模組，執行 `git add FEATURE_AUDIT_LOG.md` 暫存進度。

---

## 階段三：批次提交與報告更新 (Finalization)
1.  **批次提交 (Batch Commit)**：
    - 每完成 5 個模組，或完成一個完整的「功能模組包」後，執行一次 `git commit`。
2.  **導航總表同步**：
    - 同步更新 `FEATURE_AUDIT_LOG.md` 頂部的導航表格，反映 iOS 端最新的達成率。
