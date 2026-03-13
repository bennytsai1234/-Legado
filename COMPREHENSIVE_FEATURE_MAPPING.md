# COMPREHENSIVE_FEATURE_MAPPING.md

## 總覽
| ID | 模組名稱 | Android 責任區 | iOS 預期對應位置 | 狀態 | 備註 |
|:---|:---|:---|:---|:---|:---|
| **01** | **系統與 UI 設定** | `ui/config/`, `help/config/` | `features/settings/` | ⚠️ | 核心 Provider 已建立，UI 移植中 |

<!-- BEGIN_MAPPING_01 -->
### 01. 系統與 UI 設定

| # | Android 檔案 | 角色 | iOS 對應檔案 | 對應狀態 |
|:--|:---|:---|:---|:---|
| 1 | `AppConfig.kt` | 業務邏輯 (Config) | `settings_provider.dart` | ✅ 已對應 |
| 2 | `ThemeConfig.kt` | 業務邏輯 (Theme) | `settings_provider.dart` | ✅ 已對應 |
| 3 | `LocalConfig.kt` | 業務邏輯 (Local) | `settings_provider.dart` | ✅ 已對應 |
| 4 | `ThemeConfigFragment.kt` | UI (Fragment) | `theme_settings_page.dart` | ✅ 已對應 |
| 5 | `WelcomeConfigFragment.kt` | UI (Fragment) | `welcome_settings_page.dart` | ✅ 已對應 |
| 6 | `OtherConfigFragment.kt` | UI (Fragment) | `other_settings_page.dart` | ✅ 已對應 |
| 7 | `BackupConfigFragment.kt` | UI (Fragment) | `backup_settings_page.dart` | ✅ 已對應 |
| 8 | `ConfigActivity.kt` | UI (Activity) | `settings_page.dart` | ✅ 已對應 |
| 9 | `ConfigViewModel.kt` | 業務邏輯 (ViewModel) | `settings_provider.dart` | ✅ 已對應 |
| 10 | `CoverConfigFragment.kt` | UI (Fragment) | `settings_provider.dart` (邏輯已對應) | ⚠️ 缺失 UI |
| 11 | `ThemeListDialog.kt` | 配置 UI (Dialog) | ❌ 無對應 | ❌ 缺失 |
| 12 | `CoverRuleConfigDialog.kt` | 配置 UI (Dialog) | ❌ 無對應 | ❌ 缺失 |
| 13 | `DirectLinkUploadConfig.kt`| 配置 UI (Config) | ❌ 無對應 | ❌ 缺失 |
| 14 | `CheckSourceConfig.kt` | 配置 UI (Config) | ❌ 無對應 | ❌ 缺失 |
| 15 | `ReadBookConfig.kt` | 業務邏輯 (Config) | `settings_provider.dart` | ✅ 已對應 |
| 16 | `ReadTipConfig.kt` | 業務邏輯 (Config) | `settings_provider.dart` | ✅ 已對應 |
| 17 | `SourceConfig.kt` | 業務邏輯 (Config) | `settings_provider.dart` | ✅ 已對應 |
<!-- END_MAPPING_01 -->
