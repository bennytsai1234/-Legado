# COMPREHENSIVE_FEATURE_MAPPING.md

## 總覽
| ID | 模組名稱 | Android 責任區 | iOS 預期對應位置 | 狀態 | 備註 |
|:---|:---|:---|:---|:---|:---|
| **01** | **系統與 UI 設定** | `ui/config/`, `help/config/` | `features/settings/` | ✅ | 已完全對齊實作 |
| **02** | **資料庫與模型** | `data/entities/`, `data/dao/` | `core/models/`, `core/database/` | ✅ | 已優化效能與維護機制 |
| **03** | **核心引擎與內容處理** | `model/analyzeRule/`, `help/book/` | `core/engine/`, `core/services/` | ✅ | 已移植核心 reSegment 演算法 |
| **04** | **搜尋與書源獲取** | `model/webBook/`, `ui/book/search/` | `features/search/`, `core/services/` | ⚠️ | 結構已對應，搜尋併發邏輯待審計 |

<!-- BEGIN_MAPPING_01 -->
### 01. 系統與 UI 設定
(已完成)
<!-- END_MAPPING_01 -->

<!-- BEGIN_MAPPING_02 -->
### 02. 資料庫與模型
(已完成)
<!-- END_MAPPING_02 -->

<!-- BEGIN_MAPPING_03 -->
### 03. 核心引擎與內容處理
(已完成)
<!-- END_MAPPING_03 -->

<!-- BEGIN_MAPPING_04 -->
### 04. 搜尋與書源獲取

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `WebBook.kt` | 網路請求與解析核心 | `book_source_service.dart` | ✅ 已對應 |
| 2 | `SearchViewModel.kt` | 搜尋業務邏輯 | `search_provider.dart` | ✅ 已對應 |
| 3 | `SearchActivity.kt` | 搜尋頁面 UI | `search_page.dart` | ✅ 已對應 |
| 4 | `SearchScope.kt` | 搜尋範圍控制 | `search_provider.dart` | ⚠️ 邏輯缺失 |
| 5 | `AnalyzeUrl.kt` | 請求參數處理 | `analyze_url.dart` | ✅ 已對應 |
| 6 | `BookHelp.kt` | 目錄與正文獲取幫助 | `book_source_service.dart` | ⚠️ 部分缺失 |
<!-- END_MAPPING_04 -->
