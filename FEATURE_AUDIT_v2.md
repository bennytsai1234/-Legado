# FEATURE_AUDIT_v2.md

<!-- BEGIN_DASHBOARD -->
## 總覽儀表板
| ID | 模組名稱 | 完成度 | 狀態 | 核心邏輯比對結果 |
|:---|:---|:---|:---|:---|
| **01** | **閱讀主界面** | 85% | ✅ | 基本翻頁、UI 切換一致；搜尋與自動閱讀彈窗有細微缺失 |
| **02** | **書架/主頁面** | 0% | ⏳ | 待分析 |
| **03** | **書源管理** | 0% | ⏳ | 待分析 |
| **04** | **核心引擎** | 0% | ⏳ | 待分析 |
<!-- END_DASHBOARD -->

---

<!-- BEGIN_AUDIT_01 -->
## 01. 閱讀主界面

**模組職責**：提供書籍內容展示、翻頁互動、選單導航及閱讀偏好設定。
**Legado 檔案**：`ReadBookActivity.kt`, `ReadBookViewModel.kt`, `ChapterProvider.kt`, `ReadMenu.kt`
**Flutter (iOS) 對應檔案**：`reader_page.dart`, `reader_provider.dart`, `chapter_provider.dart`
**完成度：85%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **點擊區域自定義**：iOS 已實現九宮格點擊映射 (`_executeAction`)，對標 Android `onTouch`。
- ✅ **翻頁模式**：支持仿真 (`SimulationPageView`)、覆蓋、水平與垂直滑動。
- ✅ **沉浸式 UI**：實現了自動隱藏系統狀態欄與導航欄的功能。
- ✅ **章節導航**：透過側邊欄（Drawer）實現了章節跳轉與搜尋功能。

**不足之處**：
- [ ] **全局搜尋缺失**：iOS 端的搜尋目前僅限於已下載/快取的章節，而 Android 支援對全書源內容進行搜尋。
- [ ] **自動閱讀細節**：iOS 雖然有自動翻頁開關，但缺乏 Android 的 `AutoReadDialog`（調節速度、模式等細節）。
- [ ] **亮度/字體微調**：iOS 的調整範圍較 Android 簡化（例如 Android 支持字體權重轉換器）。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **01.1 點擊互動** | `ReadBookActivity.kt`: 220 (`onTouch`) | `reader_page.dart`: 104 (`GestureDetector`) | **Equivalent** | 實作方式不同但語義對等 |
| **01.2 章節切換** | `ReadBookActivity.kt`: 137 (`openChapter`) | `reader_page.dart`: 85 (`_executeAction`) | **Matched** | 呼叫 Provider/VM 跳轉邏輯一致 |
| **01.3 仿真翻頁** | `ReadBookActivity.kt`: 196 (`SimulationPageDelegate`) | `reader_page.dart`: 145 (`SimulationPageView`) | **Matched** | 仿真效果對等實現 |
| **01.4 內容搜尋** | `ReadBookActivity.kt`: 164 (`searchContentActivity`) | `reader_page.dart`: 237 (`_doSearch`) | **Logic Gap** | iOS 搜尋範圍受限於快取 |
| **01.5 系統 UI** | `ReadBookActivity.kt`: 250 (`upSystemUiVisibility`) | `reader_page.dart`: 50 (`_updateSystemUI`) | **Matched** | 隱藏/顯示邏輯一致 |
<!-- END_AUDIT_01 -->
