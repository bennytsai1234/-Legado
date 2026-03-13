# FEATURE_AUDIT_v2.md

<!-- BEGIN_DASHBOARD -->
## 總覽儀表板
| ID | 模組名稱 | 完成度 | 狀態 | 核心邏輯比對結果 |
|:---|:---|:---|:---|:---|
| **01** | **閱讀主界面** | 85% | ✅ | 基本翻頁、UI 切換一致；搜尋與自動閱讀彈窗有細微缺失 |
| **02** | **書架/主頁面** | 90% | ✅ | 佈局切換、分組與批量管理一致；自動備份同步邏輯有細微缺口 |
| **03** | **書源管理** | 92% | ✅ | 書源列表、編輯、匯入匯出一致；偵錯控制台與進階分組邏輯有細微缺失 |
| **04** | **核心引擎** | 88% | ✅ | 多模式規則解析、JS 引擎對齊；UMD 格式支持缺失 |
| **05** | **數據持久化** | 95% | ✅ | 數據模型、響應式監聽、位運算分組對齊；事務控制微小差異 |
| **06** | **RSS 閱覽** | 90% | ✅ | 規則解析、文章列表、收藏夾邏輯一致 |
| **07** | **背景服務** | 95% | ✅ | TTS 朗讀、HTTP TTS、本地 Web 服務對齊 |
| **08** | **系統助手/備份** | 85% | ✅ | WebDav 同步、JS 工具類對齊；統一恢復調度器缺失 |
| **09** | **替換規則** | 95% | ✅ | 正則替換、範圍控制與分組管理完全對齊 |
| **10** | **通用配置** | 92% | ✅ | 主題、備份、朗讀設定一致；字體權重微調功能缺失 |
| **11** | **底層基類** | 80% | ✅ | ViewModel/Provider 基類對齊；缺乏統一 UI 狀態 Scaffold 基類 |
| **12** | **常量與異常** | 95% | ✅ | 全局鍵值、正則模式對齊；特定 Java 異常類型簡化 |
| **13** | **工具函數庫** | 90% | ✅ | 編碼檢測、加密、文件工具一致；依賴部分原生插件 |
| **14** | **廣播與關聯** | 95% | ✅ | 媒體控制、分享接收、網路監聽邏輯高度對齊 |
| **15** | **自定義 UI 元件** | 85% | ✅ | 核心組件（電池、封面）對齊；快速滾動條等進階 UI 缺失 |
<!-- END_DASHBOARD -->

---

<!-- BEGIN_AUDIT_01 -->
...
<!-- END_AUDIT_11 -->

<!-- BEGIN_AUDIT_12 -->
## 12. 常量與異常

**模組職責**：定義全局配置鍵值、正則模式與業務異常類型。
**Legado 檔案**：`AppConst.kt`, `PreferKey.kt`, `AppPattern.kt`, `exception/`
**Flutter (iOS) 對應檔案**：`prefer_key.dart`, `app_pattern.dart`, `book_type.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **配置鍵值**：對標了所有的 SharedPreference 鍵值，確保數據遷移相容性。
- ✅ **正則庫**：實現了與 Android 一致的常見內容提取正則。

**不足之處**：
- [ ] **精細化異常**：iOS 目前合併了多種 Android 的特定異常（如 `RegexTimeoutException`）為通用的解析錯誤。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **12.1 偏好鍵值** | `PreferKey.kt`: 25 (`backupPath`) | `prefer_key.dart`: 15 (`backupPath`) | **Matched** | 名稱與預設值一致 |
| **12.2 章節模式** | `AppPattern.kt`: 10 (`chapterPattern`) | `app_pattern.dart`: 8 (`chapter`) | **Matched** | 正則表達式對齊 |
| **12.3 書籍類型** | `BookType.kt` | `book_type.dart` | **Matched** | 枚舉定義一致 |
| **12.4 事件標識** | `EventBus.kt` | `app_event_bus.dart` | **Matched** | 總線常量對齊 |
| **12.5 日誌等級** | `AppLog.kt` | `log_service.dart` | **Matched** | 日誌分級邏輯一致 |
<!-- END_AUDIT_12 -->

<!-- BEGIN_AUDIT_13 -->
## 13. 工具函數庫

**模組職責**：提供加密、編碼、文件 IO、壓縮及 QR 處理等無狀態工具。
**Legado 檔案**：`FileUtils.kt`, `EncodingDetect.kt`, `MD5Utils.kt`, `QRCodeUtils.kt`, `ZipUtils.kt`
**Flutter (iOS) 對應檔案**：`file_doc.dart`, `encoding_detect.dart`, `backup_aes_service.dart`, `qr_scan_page.dart`
**完成度：90%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **編碼檢測**：實現了基於字節特徵的文本編碼自動識別。
- ✅ **文件操作**：封裝了與 Android `DocumentFile` 語義對等的文件處理工具。
- ✅ **掃碼支持**：完美對標了書源連結與備份數據的 QR 處理。

**不足之處**：
- [ ] **壓縮算法細節**：Android 支持更豐富的 `ZipUtils` 參數調整，iOS 目前依賴 `archive` 插件的標準實現。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **13.1 編碼檢測** | `EncodingDetect.kt`: 35 (`getHtmlCharset`) | `encoding_detect.dart`: 22 (`detect`) | **Matched** | 核心檢測算法對齊 |
| **13.2 文件大小** | `FileUtils.kt`: 120 (`formatFileSize`) | `file_doc.dart`: 45 (`formatSize`) | **Matched** | 格式化邏輯一致 |
| **13.3 MD5 計算** | `MD5Utils.kt` | `backup_aes_service.dart` | **Matched** | 摘要算法對齊 |
| **13.4 QR 生成** | `QRCodeUtils.kt` | `qr_code_service.dart` | **Matched** | 生成與解析邏輯一致 |
| **13.5 JSON 擴展** | `GsonExtensions.kt` | `json_utils.dart` | **Equivalent** | iOS 使用 `jsonDecode` 對等實現 |
<!-- END_AUDIT_13 -->

<!-- BEGIN_AUDIT_14 -->
## 14. 廣播與關聯

**模組職責**：處理系統級別的事件交互，如文件分享接收、媒體按鍵監聽及網路狀態變更。
**Legado 檔案**：`SharedReceiverActivity.kt`, `MediaButtonReceiver.kt`, `NetworkChangedListener.kt`, `FileAssociationActivity.kt`
**Flutter (iOS) 對應檔案**：`intent_handler_service.dart`, `audio_play_service.dart`
**完成度：95%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **分享接收**：實現了接收外部書源連結、TXT 文件及備份包的分享處理。
- ✅ **媒體控制**：支持耳機線控、鎖屏音樂控件對朗讀播放的控制。
- ✅ **網路狀態**：實現了網路從無到有時自動觸發數據同步的邏輯。

**不足之處**：
- [ ] **Shortcut 支持**：Android 支持長按圖標顯示快捷入口（如掃一掃），iOS 目前尚未實現。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **14.1 文本分享** | `SharedReceiverActivity.kt`: 45 (`handleIntent`) | `intent_handler_service.dart`: 35 (`onSharedText`) | **Matched** | 分享內容解析邏輯一致 |
| **14.2 媒體按鍵** | `MediaButtonReceiver.kt`: 80 (`onMediaButton`) | `audio_play_service.dart`: 150 (`onControl`) | **Matched** | 控制信號映射一致 |
| **14.3 網路監聽** | `NetworkChangedListener.kt` | `app_database.dart` (部分) | **Matched** | 斷網重連同步邏輯一致 |
| **14.4 文件關聯** | `FileAssociationActivity.kt` | `intent_handler_service.dart` | **Matched** | 外部文件打開流程一致 |
| **14.5 電池監控** | `TimeBatteryReceiver.kt` | `reader_page.dart` (內建) | **Equivalent** | 均能正確讀取系統電量展示 |
<!-- END_AUDIT_14 -->

<!-- BEGIN_AUDIT_15 -->
## 15. 自定義 UI 元件

**模組職責**：提供應用內自定義的視圖組件、動畫效果及特殊的圖片渲染邏輯。
**Legado 檔案**：`CoverImageView.kt`, `BatteryView.kt`, `FastScroller.kt`, `ShadowLayout.kt`
**Flutter (iOS) 對應檔案**：`shared/widgets/`, `reader_page.dart`
**完成度：85%**
**狀態：✅**

**已完成項目 ✅**：
- ✅ **封面加載**：實現了帶緩存與預設圖的封面組件。
- ✅ **自定義電池**：實現了閱讀器內精確的電池百分比與狀態顯示。
- ✅ **加載動畫**：實現了多種對標 Android 的頁面跳轉與數據加載動畫。

**不足之處**：
- [ ] **快速滾動條**：Android 列表支持字母或進度快速拖拽導覽，iOS 目前缺乏此原生元件支持。
- [ ] **特效視圖**：Android 有 `ExplosionField`（爆炸效果）等特效元件，iOS 目前優先保證核心功能穩定。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **15.1 封面渲染** | `CoverImageView.kt` | `reader_page.dart`: 350 (`CachedNetworkImage`) | **Equivalent** | 功能完全對等 |
| **15.2 電池組件** | `BatteryView.kt` | `reader_page.dart` (內建) | **Matched** | 顯示與更新邏輯一致 |
| **15.3 二次確認框** | `TextDialog.kt` | `base_scaffold.dart` | **Matched** | 彈窗風格與邏輯一致 |
| **15.4 加載狀態** | `RotateLoading.kt` | `CircularProgressIndicator` | **Equivalent** | 視覺效果對等 |
| **15.5 分組標籤** | `LabelsBar.kt` | `ChoiceChip` | **Matched** | 標籤選擇邏輯一致 |
<!-- END_AUDIT_15 -->
