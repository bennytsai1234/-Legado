/// BookType - 書籍類型遮罩 (對標 Android constant/BookType.kt)
/// 採用位元運算以支援多重類型
class BookType {
  static const int text = 1; // 文本
  static const int audio = 2; // 音訊
  static const int image = 4; // 圖片
  static const int file = 8; // 文件
  static const int local = 16; // 本地
  static const int updateError = 32; // 更新錯誤
  static const int notShelf = 64; // 不在書架 (例如搜尋結果)
  
  static const String localTag = "local";
  static const String webDavTag = "webdav";
}

/// BookSourceType - 書源類型 (對標 Android constant/BookSourceType.kt)
class BookSourceType {
  static const int defaultType = 0; // 文本
  static const int audio = 1; // 音訊
  static const int image = 2; // 圖片
  static const int file = 3; // 只提供下載服務的網站
}

/// SourceType - 源大類 (對標 Android constant/SourceType.kt)
class SourceType {
  static const int book = 0;
  static const int rss = 1;
}
