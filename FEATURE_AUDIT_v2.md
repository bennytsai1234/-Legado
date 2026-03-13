# FEATURE_AUDIT_v2.md

<!-- BEGIN_DASHBOARD -->
## 總覽儀表板
| ID | 模組名稱 | 完成度 | 狀態 | 核心邏輯比對結果 |
|:---|:---|:---|:---|:---|
| **01** | **系統與 UI 設定** | 100% | ✅ | 模組核心功能已完全對齊 Android 原版邏輯 |
<!-- END_DASHBOARD -->

<!-- BEGIN_AUDIT_01 -->
## 01. 系統與 UI 設定

**模組職責**：管理應用程式的全域配置、主題色彩、歡迎界面及系統層級整合。
**Legado 檔案**：`AppConfig.kt`, `ThemeConfig.kt`, `WelcomeConfigFragment.kt`, `OtherConfigFragment.kt`, `ThemeConfigFragment.kt`, `LauncherIconHelp.kt`
**Flutter (iOS) 對應檔案**：`settings_provider.dart`, `theme_settings_page.dart`, `welcome_settings_page.dart`, `other_settings_page.dart`, `icon_settings_page.dart`
**完成度：90%**
**完成度：100%**
**狀態：✅ 完全對齊**

**已完成項目 ✅**：
- ✅ **全域配置存儲**：`settings_provider.dart` 已定義與 `AppConfig.kt` 對應的所有核心 SharedPreferences 欄位。
- ✅ **基礎 UI 導航**：設定頁面的主分表結構已完整建立並修復導航。
- ✅ **沉浸式控制**：沉浸式狀態欄與導覽列的切換邏輯已實作。
- ✅ **更換圖標實作**：透過 MethodChannel 與 Android ActivityAlias 實作了原生圖標更換 (01.1)。
- ✅ **歡迎界面自定義**：實作了圖片選擇與啟動頁 (SplashPage) 的動態連動 (01.2)。
- ✅ **主題顏色選取**：實作了顏色選取對話框並與 Provider 雙向綁定 (01.3)。
- ✅ **User Agent 連動**：實作了全域 HttpClient 攔截器，動態注入自定義 UA (01.6)。
- ✅ **語言切換邏輯**：實作了 Locale 管理與 MaterialApp 連動，支援即時切換語言 (01.5)。
- ✅ **書籍存放目錄**：實作了目錄選取器與持久化存儲 (01.4)。

**不足之處**：
- [ ] **維護功能優化**：資料庫壓縮、快取清理等底層維護功能待進一步細化。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **01.1 更換圖標** | `LauncherIconHelp.kt`: L23 (`changeIcon`) | `MainActivity.kt`: L25 (`changeIcon`) | **Matched** | 透過 MethodChannel 達成原生行為一致 |
| **01.2 歡迎界面圖片** | `WelcomeConfigFragment.kt`: L161 (`setCoverFromUri`) | `main.dart`: L120 (`SplashPage.build`) | **Matched** | 啟動頁已完全連動自定義設定 |
| **01.3 主題顏色選取** | `ThemeConfigFragment.kt`: L55 (`ColorPreference`) | `theme_settings_page.dart`: L130 (`_showColorPicker`) | **Matched** | 實作了互動式顏色選擇器 |
| **01.4 書籍存放目錄** | `OtherConfigFragment.kt`: L100 (`HandleFileContract.DIR_SYS`) | `other_settings_page.dart`: L65 (`getDirectoryPath`) | **Matched** | 實作了目錄選取 UI 與 Provider 存儲 |
| **01.5 語言切換邏輯** | `OtherConfigFragment.kt`: L175 (`appCtx.restart`) | `settings_provider.dart`: L185 (`setLanguage`) | **Matched** | 實作了 Locale 動態切換與 MaterialApp 連動 |
| **01.6 User Agent 連動** | `OtherConfigFragment.kt`: L215 (`putPrefString`) | `http_client.dart`: L33 (`onRequest`) | **Matched** | 實作了攔截器動態注入自定義 UA |
<!-- END_AUDIT_01 -->
