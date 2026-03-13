# FEATURE_AUDIT_v2.md

<!-- BEGIN_DASHBOARD -->
## 總覽儀表板
| ID | 模組名稱 | 完成度 | 狀態 | 核心邏輯比對結果 |
|:---|:---|:---|:---|:---|
| **01** | **系統與 UI 設定** | 100% | ✅ | 模組核心功能已完全對齊 Android 原版邏輯 |
| **02** | **資料庫與模型** | 100% | ✅ | 模組核心功能已完全對齊 Android 原版邏輯 |
| **03** | **核心引擎與內容處理** | 100% | ✅ | 模組核心功能已完全對齊 Android 原版邏輯 |
| **04** | **搜尋與書源獲取** | 70% | ⚠️ | 已實作並發控制，但搜尋排序權重與多選過濾缺失 |
<!-- END_DASHBOARD -->

<!-- BEGIN_AUDIT_01 -->
(已完成)
<!-- END_AUDIT_01 -->

<!-- BEGIN_AUDIT_02 -->
(已完成)
<!-- END_AUDIT_02 -->

<!-- BEGIN_AUDIT_03 -->
(已完成)
<!-- END_AUDIT_03 -->

<!-- BEGIN_AUDIT_04 -->
## 04. 搜尋與書源獲取

**模組職責**：跨書源並發搜尋、結果聚合、去重與排序、搜尋範圍控制。
**Legado 檔案**：`WebBook.kt`, `SearchViewModel.kt`, `SearchScope.kt`, `BookHelp.kt`
**Flutter (iOS) 對應檔案**：`book_source_service.dart`, `search_provider.dart`, `search_page.dart`
**完成度：70%**
**狀態：⚠️ 部分缺失**

**已完成項目 ✅**：
- ✅ **並發控制**：實作了基於 `pool` 的執行緒數量控制，對標 Android 的 `threadCount`。
- ✅ **結果聚合**：已實作基礎的「書名+作者」去重聚合邏輯。
- ✅ **歷史紀錄**：具備基本的搜尋歷史管理。

**不足之處**：
- [ ] **權重排序缺失 (04.1)**：未引入書源權重 (Weight) 進行結果排序，導致優質來源可能被埋沒。
- [ ] **多選過濾限制 (04.2)**：搜尋範圍 (Scope) 目前僅支持單選分組，無法像 Android 般自由組合搜尋範圍。
- [ ] **任務超時機制 (04.3)**：缺乏針對單一書源 Task 的超時取消，慢速書源會阻塞 Pool 資源。
- [ ] **精準去重優化 (04.4)**：未實作作者名正規化處理（如去除括號、空格等），導致聚合準確度低於 Android。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **04.1 並發資源管理** | `WebBook.kt`: L30 (`Semaphore`) | `search_provider.dart`: L100 (`Pool`) | **Matched** | 實作方式一致 |
| **04.2 搜尋排序權重** | `SearchViewModel.kt`: `sortResults` | `search_provider.dart`: L165 (`sort`) | **Gap** | iOS 僅依來源數排序，忽略了書源本身的權重欄位 |
| **04.3 多分組過濾** | `SearchScope.kt`: `checkedGroups` | `search_provider.dart`: L85 (`_selectedGroup`) | **Logic Gap** | iOS 目前僅支持單選，UI 與邏輯均需升級為多選 |
| **04.4 去重逻辑** | `BookHelp.kt`: `formatAuthor` | `search_provider.dart`: L140 (`indexWhere`) | **Partial** | 缺乏對作者名稱的淨化處理 |
<!-- END_AUDIT_04 -->
