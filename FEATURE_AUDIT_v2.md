# 🔍 審計報告：legado/app/src/main/java/io/legado/app/constant

### 📄 檔案對比清單
| 檔案名稱 | 狀態 | 診斷詳情 |
|:---|:---|:---|
| `AppConst.kt` | ❌ Missing | **移植規格**：iOS 嚴重缺失全域常數。需建立 `lib/core/constant/app_const.dart`，移植 `MAX_THREAD`, `UA_NAME`, `charsets` 以及版本變體判定邏輯。 |
| `AppLog.kt` | ❌ Missing | **移植規格**：需在 `app_const.dart` 或獨立檔案定義日誌等級常數。 |
| `AppPattern.kt` | ✅ Matched | `lib/core/constant/app_pattern.dart` 已大致對位，但漏掉了 `bdRegex` 的特殊 unicode 標點符號處理。 |
| `BookSourceType.kt` | ✅ Matched | 已併入 iOS 的 `lib/core/constant/book_type.dart` 中。 |
| `BookType.kt` | ⚠️ Partial | **數值不匹配**：Android 端 `text` 為 `0b1000` (8)，iOS 端卻定義為 `1`。這會導致資料庫與書源解析時類型判斷失效，必須修正為對應的二進位位元。 |
| `EventBus.kt` | ❌ Missing | **移植規格**：Flutter 中建議直接使用 `Stream` 或自定義 `AppEventBus`。 |
| `IntentAction.kt` | ❌ Missing | **不需移植**：屬 Android 系統原生通訊機制。 |
| `NotificationId.kt` | ❌ Missing | **不需移植**：由 iOS 系統通知 ID 管理機制替代。 |
| `PageAnim.kt` | ❌ Missing | **待實作**：iOS 目前讀者介面缺乏動畫模式定義，需在 `lib/core/constant/page_anim.dart` 補齊 `simulation`, `scroll` 等類型定義。 |
| `PreferKey.kt` | ✅ Matched | `lib/core/constant/prefer_key.dart` 已對位，但 iOS 版缺少了約 40% 的進階配置鍵名。 |
| `SourceType.kt` | ✅ Matched | 已併入 iOS 的 `lib/core/constant/book_type.dart`。 |
| `Status.kt` | ❌ Missing | **移植規格**：需定義朗讀播放狀態（STOP/PLAY/PAUSE）。 |
| `Theme.kt` | ❌ Missing | **移植規格**：iOS 端 `themeMode` 目前使用 String，應統一為 `enum Theme { dark, light, auto }`。 |

### 🛠️ 待辦缺口 (Todo Gaps)
- [x] GAP-CONST-01: 建立 `app_const.dart` 並移植關鍵常數（尤其是 `charsets` 支援清單）。 ✅ Done in 2026-03-13
- [x] GAP-CONST-02: 修正 `book_type.dart` 中的數值，使其與 Android 端原始二進位定義一致（避免舊資料解析錯誤）。 ✅ Done in 2026-03-13
- [x] GAP-CONST-03: 在 `book_type.dart` 補齊 `webDavTag` 為 `"webDav::"` (目前 iOS 為 `"webdav"`)，確保書源 URL 兼容性。 ✅ Done in 2026-03-13
- [x] GAP-CONST-04: 補齊 `prefer_key.dart` 中遺漏的鍵值（如朗讀與 UI 定製項）。 ✅ Done in 2026-03-13
- [x] GAP-CONST-05: 建立 `page_anim.dart` 支援多樣化翻頁效果定義。 ✅ Done in 2026-03-13
