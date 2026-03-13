# COMPREHENSIVE_FEATURE_MAPPING.md

## 總覽
| ID | 模組名稱 | Android 責任區 | iOS 預期對應位置 | 狀態 | 備註 |
|:---|:---|:---|:---|:---|:---|
| **01** | **閱讀主界面** | `ui/book/read/` | `features/reader/` | ✅ | 包含閱讀器、配置、導航 |
| **02** | **書架/主頁面** | `ui/main/` | `features/bookshelf/` | ✅ | 書架、分組管理 |
| **03** | **書源管理** | `ui/book/source/` | `features/source_manager/` | ✅ | 書源列表、編輯、調試 |

---

<!-- BEGIN_MAPPING_01 -->
### 01. 閱讀主界面

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `ReadBookActivity.kt` | UI (Activity) | `reader_page.dart` | ✅ 已對應 |
| 2 | `ReadBookViewModel.kt` | 業務邏輯 (ViewModel) | `reader_provider.dart` | ✅ 已對應 |
| 3 | `BaseReadBookActivity.kt` | UI (Base) | `reader_page.dart` (合併) | ⚠️ 部分合併 |
| 4 | `ReadMenu.kt` | UI (Menu) | `reader_page.dart` (UI 部分) | ⚠️ 部分合併 |
| 5 | `PageView.kt` | UI (Custom View) | `page_view_widget.dart` | ✅ 已對應 |
| 6 | `ReadView.kt` | UI (Custom View) | `page_view_widget.dart` | ✅ 已對應 |
| 7 | `ChapterProvider.kt` | 資料解析/佈局 (Provider) | `engine/chapter_provider.dart` | ✅ 已對應 |
| 8 | `TextPageFactory.kt` | 邏輯 (Factory) | `engine/text_page.dart` | ✅ 已對應 |
| 9 | `SimulationPageDelegate.kt` | 翻頁動畫 (Delegate) | `engine/simulation_page_view.dart` | ✅ 已對應 |
| 10 | `AutoReadDialog.kt` | 配置 UI (Dialog) | `reader_page.dart` (對話框暫缺) | 🚨 嚴重缺失 |
<!-- END_MAPPING_01 -->

<!-- BEGIN_MAPPING_02 -->
### 02. 書架/主頁面

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `MainActivity.kt` | UI (Activity) | `bookshelf_page.dart` | ✅ 已對應 |
| 2 | `MainViewModel.kt` | 業務邏輯 (ViewModel) | `bookshelf_provider.dart` | ✅ 已對應 |
| 3 | `BookshelfManageActivity.kt` | UI (Activity) | `bookshelf_page.dart` (編輯模式) | ⚠️ 部分合併 |
| 4 | `GroupManageDialog.kt` | UI (Dialog) | `group_manage_page.dart` | ✅ 已對應 |
<!-- END_MAPPING_02 -->

<!-- BEGIN_MAPPING_03 -->
### 03. 書源管理

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `BookSourceActivity.kt` | UI (Activity) | `source_manager_page.dart` | ✅ 已對應 |
| 2 | `BookSourceViewModel.kt` | 業務邏輯 (ViewModel) | `source_manager_provider.dart` | ✅ 已對應 |
| 3 | `BookSourceEditActivity.kt` | UI (Activity) | `source_editor_page.dart` | ✅ 已對應 |
| 4 | `BookSourceDebugActivity.kt` | UI (Activity) | `debug_page.dart` (部分) | ⚠️ 部分對應 |
<!-- END_MAPPING_03 -->
