# 🗺️ 綜合功能對位地圖 (Comprehensive Feature Mapping)
本文件記錄了 Android (Legado) 與 iOS (Flutter) 專案之間的原始碼對位關係。

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/constant

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `AppConst.kt` | 全域常數、支援格式、超時設定 | - | ❌ Missing |
| `AppLog.kt` | 紀錄層級、日誌相關標記 | - | ❌ Missing |
| `AppPattern.kt` | 正規表達式模式定義 (日期、URL 等) | `lib/core/constant/app_pattern.dart` | ✅ Matched |
| `BookSourceType.kt` | 書源類型列舉 (文字、音訊等) | - | ❌ Missing |
| `BookType.kt` | 書籍類型 (本地、網路等) | `lib/core/constant/book_type.dart` | ✅ Matched |
| `EventBus.kt` | 事件總線標記 (雖然 Flutter 多用 Stream) | - | ❌ Missing |
| `IntentAction.kt` | Android Intent 動作定義 | - | ❌ Missing |
| `NotificationId.kt` | 通知 ID 定義 | - | ❌ Missing |
| `PageAnim.kt` | 翻頁動畫類型 | - | ❌ Missing |
| `PreferKey.kt` | SharedPreferences 鍵名定義 | `lib/core/constant/prefer_key.dart` | ✅ Matched |
| `SourceType.kt` | 來源類型 (書源、RSS) | - | ❌ Missing |
| `Status.kt` | 下載或同步狀態 | - | ❌ Missing |
| `Theme.kt` | 主題相關常數 | - | ❌ Missing |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/exception

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ConcurrentException.kt` | 併發衝突異常 | - | ❌ Missing |
| `ContentEmptyException.kt` | 內容為空異常 | - | ❌ Missing |
| `EmptyFileException.kt` | 檔案為空異常 | - | ❌ Missing |
| `InvalidBooksDirException.kt` | 書籍目錄無效異常 | - | ❌ Missing |
| `NoBooksDirException.kt` | 書籍目錄不存在異常 | - | ❌ Missing |
| `NoStackTraceException.kt` | 無堆疊軌跡異常基類 | - | ❌ Missing |
| `RegexTimeoutException.kt` | 正則匹配超時異常 | - | ❌ Missing |
| `TocEmptyException.kt` | 目錄為空異常 | - | ❌ Missing |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/utils

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ACache.kt` | 磁碟緩存工具 | - | ❌ Missing |
| `ActivityExtensions.kt` | Activity 視窗與 UI 擴展 | - | ❌ Missing |
| `ArchiveUtils.kt` | 壓縮擋 (ZIP/7z) 處理 | - | ❌ Missing |
| `BitmapUtils.kt` / `ImageUtils.kt` | 圖片處理、縮放、裁剪 | - | ❌ Missing |
| `ChineseUtils.kt` | 繁簡轉換 | `lib/core/services/chinese_utils.dart` | ✅ Matched |
| `ColorUtils.kt` | 顏色解析、轉換 | - | ❌ Missing |
| `ContextExtensions.kt` | Context 相關 (螢幕、權限、路徑) | - | ❌ Missing |
| `CookieManagerExtensions.kt` | Cookie 獲取與儲存 | - | ❌ Missing |
| `EncoderUtils.kt` / `MD5Utils.kt` | 編碼 (Base64/MD5) | `lib/core/engine/js/js_encode_utils.dart` | ⚠️ Partial |
| `EncodingDetect.kt` | 文件編碼自動偵測 | `lib/core/services/encoding_detect.dart` | ✅ Matched |
| `FileDocExtensions.kt` | 虛擬文件管理 (SAF) | `lib/core/storage/file_doc.dart` | ✅ Matched |
| `FileUtils.kt` | 基礎檔案操作 | `lib/core/storage/file_doc.dart` | ⚠️ Partial |
| `GsonExtensions.kt` / `JsonExtensions.kt` | JSON 解析封裝 | `dart:convert` (內建) | ✅ Matched |
| `HtmlFormatter.kt` / `JsoupExtensions.kt` | HTML 內容清理與格式化 | `lib/core/services/content_processor.dart` | ⚠️ Partial |
| `NetworkUtils.kt` | 代理、UA、網路狀態檢查 | - | ❌ Missing |
| `QRCodeUtils.kt` | 二維碼生成與識別 | - | ❌ Missing |
| `StringUtils.kt` / `StringExtensions.kt` | 字串處理、格式檢查 | `dart:core` (內建擴展) | ✅ Matched |
| `TimeUtils.kt` | 時間格式化、時差計算 | - | ❌ Missing |
| `ToastUtils.kt` / `Snackbars.kt` | 提示訊息 UI | - | ❌ Missing |
| `UriExtensions.kt` / `UrlUtil.kt` | URL 解析、編碼、合併 | - | ❌ Missing |
| `*Extensions.kt` (其他 40+ 檔案) | Android SDK 特有的擴展方法 | - | ❌ Missing |

---

## 📂 資料夾路徑：legado/app/src/main/java/io/legado/app/utils/compress

| Android 檔案 | 職責描述 | iOS 對位檔案 | 狀態 |
|:---|:---|:---|:---|
| `ZipUtils.kt` | ZIP 壓縮與解壓 | - | ❌ Missing |

---

## 遞迴進度回報
- [x] `constant`
- [x] `exception`
- [x] `utils`
- [ ] `help`
- [ ] `model`
- [ ] `data`
- [ ] `service`
- [ ] `ui`
