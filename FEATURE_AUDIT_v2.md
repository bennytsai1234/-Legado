# FEATURE_AUDIT_v2.md

<!-- BEGIN_DASHBOARD -->
## 總覽儀表板
| ID | 模組名稱 | 完成度 | 狀態 | 核心邏輯比對結果 |
|:---|:---|:---|:---|:---|
| **01** | **系統與 UI 設定** | 45% | 🚨 | 骨架已對應，但 80% 的 UI 互動均為 Placeholder |
<!-- END_DASHBOARD -->

<!-- BEGIN_AUDIT_01 -->
## 01. 系統與 UI 設定

**模組職責**：管理應用程式的全域配置、主題色彩、歡迎界面及系統層級整合。
**Legado 檔案**：`AppConfig.kt`, `ThemeConfig.kt`, `WelcomeConfigFragment.kt`, `OtherConfigFragment.kt`, `ThemeConfigFragment.kt`, `LauncherIconHelp.kt`
**Flutter (iOS) 對應檔案**：`settings_provider.dart`, `theme_settings_page.dart`, `welcome_settings_page.dart`, `other_settings_page.dart`, `icon_settings_page.dart`
**完成度：45%**
**狀態：🚨 嚴重缺失**

**已完成項目 ✅**：
- ✅ **全域配置存儲**：`settings_provider.dart` 已定義大部分與 `AppConfig.kt` 對應的 SharedPreferences 欄位。
- ✅ **基礎 UI 導航**：設定頁面的主分表結構已建立。
- ✅ **沉浸式控制**：沉浸式狀態欄與導覽列的切換邏輯已初步實作。

**不足之處**：
- [ ] **UI 功能空洞**：`ThemeSettingsPage` 與 `OtherSettingsPage` 中超過 10 個 ListTile 點擊後僅顯示「功能開發中」。
- [ ] **系統層級整合缺失**：更換圖標（`LauncherIconHelp`）與系統語言切換邏輯完全未與原生平台對接。
- [ ] **互動邏輯缺失**：顏色選擇器、文件路徑選取（書籍目錄）等關鍵互動完全未實作。
- [ ] **維護功能缺失**：資料庫壓縮（Shrink）、快取清理、User Agent 變更生效邏輯均未實作。

### 證據鏈明細

| 邏輯點 | Android 證據鏈 | iOS 證據鏈 | 狀態 | 狀態描述 |
| :--- | :--- | :--- | :--- | :--- |
| **01.1 更換圖標** | `LauncherIconHelp.kt`: L23 (`changeIcon`) | `theme_settings_page.dart`: L18 (`_showComingSoon`) | **Logic Gap** | iOS 端僅有 UI 骨架，完全無功能實作 |
| **01.2 歡迎界面圖片** | `WelcomeConfigFragment.kt`: L161 (`setCoverFromUri`) | `welcome_settings_page.dart`: L71 (`_pickImage`) | **Equivalent** | 圖片選取已實作，但 `SplashPage` 未完全連動 |
| **01.3 主題顏色選取** | `ThemeConfigFragment.kt`: L55 (`ColorPreference`) | `theme_settings_page.dart`: L118 (`_showComingSoon`) | **Logic Gap** | 點擊顏色塊後無任何回應 |
| **01.4 書籍存放目錄** | `OtherConfigFragment.kt`: L100 (`HandleFileContract.DIR_SYS`) | `other_settings_page.dart`: L65 (`_showComingSoon`) | **Logic Gap** | 無法設定自定義目錄 |
| **01.5 語言切換邏輯** | `OtherConfigFragment.kt`: L175 (`appCtx.restart`) | `other_settings_page.dart`: L18 (`_showComingSoon`) | **Logic Gap** | 點擊切換語言無任何回應 |
| **01.6 User Agent 連動** | `OtherConfigFragment.kt`: L215 (`putPrefString`) | `other_settings_page.dart`: L61 (`_showComingSoon`) | **Logic Gap** | 欄位已存在於 Provider 但 UI 無法編輯且 HttpClient 未連動 |
<!-- END_AUDIT_01 -->
