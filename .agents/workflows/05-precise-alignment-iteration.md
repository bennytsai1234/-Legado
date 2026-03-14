---
description: "[5/5] 精準對位迭代工作流：針對 Android 邏輯進行深度復刻與 Flutter 精準實作"
---

# 🎯 [5/5] 精準對位迭代工作流 (Precise Alignment) v1

本工作流專注於將 Android (Legado) 的核心功能「精確且穩定」地移植到 iOS (Flutter) 專案。不追求開發速度，但求邏輯對位、語法零警告與功能完善。

---

## 🔄 核心循環 (The Alignment Cycle)

### 1. 模組定位 (Gap Identification)
- 參考 `COMPREHENSIVE_FEATURE_MAPPING.md` 找出目前的缺口（❌ Missing 或 ⚠️ Partial）。
- 優先處理具有核心邏輯影響的模組（如：瀏覽器、調試器、字體管理）。

### 2. Android 原始碼審計 (Android Source Audit)
- 使用 `Get-ChildItem` 掃描 `legado/app/src/main/java/io/legado/app/ui/[模組]`。
- 讀取關鍵檔案：
    - **Activity/Fragment**: 瞭解 UI 互動與事件流。
    - **ViewModel**: 瞭解資料處理與業務邏輯。
    - **Entity/Dao**: 瞭解資料結構。
- 總結核心職責（例如：Cookie 捕獲、正規表達式測試、全域字體加載）。

### 3. Flutter 對位實作 (Flutter Implementation)
- **Model**: 確保 JSON 序列化與欄位命名與 Android 對標。
- **Provider**: 承接 ViewModel 的職責，使用 `BaseProvider` 規範 Loading 狀態。
- **Page/Widget**: 復刻 Android 的交互習慣（如：長按選單、終端機日誌風格、預覽文字）。
- **Wiring**: 將新功能整合至 `main.dart` (MultiProvider) 或相關入口。

### 4. 靜態分析與深度除錯 (Static Analysis & Hardening)
- 執行 `flutter analyze ios`。
- **嚴格標準**：必須修正所有問題，包含 `info` 級別的警告。
    - 修正 `use_build_context_synchronously`。
    - 修正 `deprecated_member_use`。
    - 修正 `unused_import` 與 `unused_field`。
- 重複執行分析直到輸出為 `No issues found!`。

### 5. 原子備份 (Atomic Backup)
- 每完成一個功能點並通過分析後，立即提交 Git。
- `git add . ; git commit -m "feat: implement [模組] ([路徑]) and UI integration"`

---

## 🛠️ 常用指令
- **掃描 Android**: `Get-ChildItem -Path "legado\app\src\main\java\io\legado\app\ui\..." -Recurse`
- **驗證代碼**: `flutter analyze ios`
- **編譯測試**: `flutter build apk --debug` (用於 Android 邏輯驗證)

## 🏁 完成判定
- ✅ 功能邏輯與 Android 版對等。
- ✅ `flutter analyze` 無任何警告或錯誤。
- ✅ `COMPREHENSIVE_FEATURE_MAPPING.md` 已同步更新狀態。
