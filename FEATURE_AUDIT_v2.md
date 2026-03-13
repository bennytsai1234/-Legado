# 🔍 審計報告：legado/app/src/main/java/io/legado/app/constant

### 📄 檔案對比清單
| 檔案名稱 | 狀態 | 診斷詳情 |
|:---|:---|:---|
| `AppConst.kt` | ✅ Matched | 已建立 `lib/core/constant/app_const.dart` 並移植關鍵常數。 |
| `AppLog.kt` | ✅ Matched | 已建立 `lib/core/services/app_log_service.dart` 實作日誌緩存。 |
| `AppPattern.kt` | ✅ Matched | `lib/core/constant/app_pattern.dart` 已對位。 |
| `BookSourceType.kt` | ✅ Matched | 已併入 `lib/core/constant/book_type.dart`。 |
| `BookType.kt` | ✅ Matched | 位元運算值已與 Android 端一致。 |
| `EventBus.kt` | ✅ Matched | 已確認 Flutter 使用 `Stream` 或第三方 `event_bus` 替代。 |
| `IntentAction.kt` | ✅ Matched | 已確認不需移植或已有對應解決方案。 |
| `NotificationId.kt` | ✅ Matched | 已確認 iOS 使用專屬 ID 機制。 |
| `PageAnim.kt` | ✅ Matched | 已建立 `lib/core/constant/page_anim.dart`。 |
| `PreferKey.kt` | ✅ Matched | 配置鍵名已完整同步。 |
| `SourceType.kt` | ✅ Matched | 已併入 `lib/core/constant/book_type.dart`。 |
| `Status.kt` | ✅ Matched | 已在 `app_const.dart` 中建立 `PlaybackStatus` 列舉。 |
| `Theme.kt` | ✅ Matched | 已在 `app_const.dart` 中建立 `AppTheme` 列舉。 |

### 🛠️ 待辦缺口 (Todo Gaps)
- [x] GAP-CONST-01: 建立 `app_const.dart` 並移植關鍵常數（尤其是 `charsets` 支援清單）。 ✅ Done in 2026-03-13
- [x] GAP-CONST-02: 修正 `book_type.dart` 中的數值，使其與 Android 端原始二進位定義一致（避免舊資料解析錯誤）。 ✅ Done in 2026-03-13
- [x] GAP-CONST-03: 在 `book_type.dart` 補齊 `webDavTag` 為 `"webDav::"` (目前 iOS 為 `"webdav"`)，確保書源 URL 兼容性。 ✅ Done in 2026-03-13
- [x] GAP-CONST-04: 補齊 `prefer_key.dart` 中遺漏的鍵值（如朗讀與 UI 定製項）。 ✅ Done in 2026-03-13
- [x] GAP-CONST-05: 建立 `page_anim.dart` 支援多樣化翻頁效果定義。 ✅ Done in 2026-03-13
- [x] GAP-CONST-06: 實作 `lib/core/services/app_log.dart` 用於捕捉全域錯誤。 ✅ Done in 2026-03-13
- [x] GAP-CONST-07: 在 `app_const.dart` 補齊 `PlaybackStatus` 與 `AppTheme` 列舉。 ✅ Done in 2026-03-13
- [x] GAP-CONST-08: 執行二次深度審計，補齊 `PreferKey` (190+ 鍵名) 與 `BookType` 遮罩。 ✅ Verified 100% on 2026-03-13
