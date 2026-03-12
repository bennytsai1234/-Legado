# 🔍 Legado Android ↔ iOS Reader 功能對齊審計報告 (Feature Parity Audit) v2

本報告基於物理地圖，深入分析 Android 與 iOS 端之邏輯差異。

## 📊 總覽儀表板

| 模組 ID | 模組名稱 | 完成度 | 狀態 | 待辦亮點 |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **核心資料實體** | 90% | ✅ | `Book.migrateTo` 邏輯對齊, 書源錯誤註釋維護 |
| **2** | **主介面與書架** | 95% | ✅ | 分組位運算過濾、批量操作、URL 匯入完全匹配 |
| **3** | **核心閱讀器** | 85% | ⚠️ | 分頁邏輯 (ChapterProvider) 等效，內容淨化規則需精細化 |
| **4** | **書源管理** | 90% | ✅ | 書源遷移 (migrateSource) 與 匯入/導出邏輯匹配 |
| **5** | **搜尋功能** | 90% | ✅ | 併發搜尋 (Pool 控制) 與 結果聚合匹配 |
| **6** | **RSS 訂閱** | 75% | ⚠️ | 框架已建立，自動未讀追蹤與複雜發現規則待補齊 |
| **7** | **替換規則** | 95% | ✅ | 正則替換邏輯與批量操作匹配 |

---

## 1. 核心資料實體 (Core Data Models)

**模組職責**：定義書籍、書源等核心資料結構及其基礎業務邏輯。
**Legado 檔案**：`data/entities/`
**Flutter (iOS) 對應檔案**：`core/models/`
**完成度：100%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ 書籍 (`Book`) 基本屬性與位元運算擴展示範。
- ✅ 書源 (`BookSource`) 完整 3.0 規則實體化。
- ✅ JSON 序列化與反序列化邏輯（含動態類型相容）。
- ✅ **1.1.1**：iOS `Book.migrateTo` 實作基於標題與數字的章節對齊邏輯。
- ✅ **1.1.2**：iOS `Book.getUseReplaceRule` 已實作對 `isImage/isEpub` 的自動判定。
- ✅ **1.2.1**：iOS `BookSource` 實作錯誤註釋 (`ErrorComment`) 的自動維護與清理。
- ✅ **1.2.2**：iOS `BookSource` 實作「失效分組」的自動清理邏輯。

**不足之處**：
- (暫無，模組 1 已完成對齊)

---

## 2. 主介面與書架 (Main & Bookshelf)

**模組職責**：書籍展示、分組過濾、排序與批量管理。
**Legado 檔案**：`ui/main/`
**Flutter (iOS) 對應檔案**：`features/bookshelf/`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ 分組過濾：使用與 Android 一致的位元運算過濾邏輯。
- ✅ 批量操作：支援批量刪除、分組變更。
- ✅ 排序邏輯：支援手動排序與自動排序模式切換。

**不足之處**：
- (暫無，書架提醒邏輯已與 Android 對齊)

---

## 3. 核心閱讀器 (Core Reader)

**模組職責**：正文解析、分頁渲染、TTS 朗讀與 WebDAV 同步。
**Legado 檔案**：`ui/book/read/`
**Flutter (iOS) 對應檔案**：`features/reader/`
**完成度：85%**
**狀態：⚠️**

**已完成項目 ✅**：
- ✅ 分頁算法：`ChapterProvider.paginate` 模擬了 Android 的文本分段邏輯。
- ✅ WebDAV：支援進度雲端同步。
- ✅ TTS 朗讀：整合了系統 TTS 與自定義 HTTP TTS。
- ✅ **3.1.1**：正則處理與取代規則範圍判斷已與 Android 對齊。
- ✅ **3.1.2**：移植了 `ContentHelp.reSegment` 核心排版優化算法。

**不足之處**：
- (暫無，核心解析邏輯已對齊)

---

## 4. 書源管理 (Source Management)

**模組職責**：書源列表、編輯、遷移與安全性檢查。
**Legado 檔案**：`ui/book/source/`
**Flutter (iOS) 對應檔案**：`features/source_manager/`
**完成度：90%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ 書源遷移：`migrateSource` 邏輯對標 Android，可自動更新書籍關聯。
- ✅ 導入導出：支援 JSON 檔案、URL 與 剪貼簿 導入。
- ✅ **4.1.1**：實作了書源校驗失敗自動記錄錯誤註釋 (ErrorComment) 邏輯。

**不足之處**：
- (暫無，校驗維護邏輯已對齊)

---

## 5. 搜尋功能 (Search)

**模組職責**：多源併發搜尋、關鍵字歷史與結果聚合。
**Legado 檔案**：`ui/book/search/`
**Flutter (iOS) 對應檔案**：`features/search/`
**完成度：90%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ 併發控制：使用 `Pool` 模擬 Android 的線程池搜尋。
- ✅ 結果聚合：跨源結果去重與排序邏輯匹配。

---

## 6. RSS 訂閱 (RSS)

**模組職責**：RSS 源管理、文章加星與自動更新。
**Legado 檔案**：`ui/rss/`
**Flutter (iOS) 對應檔案**：`features/rss/`
**完成度：85%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ 核心框架：支援 RSS 2.0/Atom 解析與展示。
- ✅ **6.1.1**：補齊了 `RssArticle` 閱讀狀態與 `RssSource` 未讀計數框架。

**不足之處**：
- [ ] **6.1.2**：自動定時抓取與未讀通知尚未實作。

---

## 7. 替換規則 (Replace Rules)

**模組職責**：文本替換規則之管理與正則執行。
**Legado 檔案**：`ui/replace/`
**Flutter (iOS) 對應檔案**：`features/replace_rule/`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ 正則替換：支援與 Android 一致的正則與批量執行。

---

### 證據鏈明細 (部分示例)

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **2.1 分組過濾** | `MainViewModel.kt`: L102 | `bookshelf_provider.dart`: L80 | **Matched** | 位元運算邏輯一致 |
| **3.1 分頁渲染** | `ReadBookViewModel.kt`: L450 | `chapter_provider.dart`: L210 | **Equivalent** | 實現方式不同但結果對等 |
| **4.2 書源遷移** | `BookSourceViewModel.kt`: L310 | `source_manager_provider.dart`: L133 | **Matched** | 核心遷移動作一致 |
