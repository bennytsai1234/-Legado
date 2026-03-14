/// BookType - 書籍類型遮罩 (對標 Android constant/BookType.kt)
/// 採用位元運算以支援多重類型
class BookType {
  // 書籍屬性標籤 (位元遮罩)
  static const int text = 0x08; // 8: 文本
  static const int updateError = 0x10; // 16: 更新失敗
  static const int audio = 0x20; // 32: 音訊
  static const int image = 0x40; // 64: 圖片
  static const int webFile = 0x80; // 128: 只提供下載服務的網站
  static const int local = 0x100; // 256: 本地
  static const int archive = 0x200; // 512: 壓縮包
  static const int notShelf = 0x400; // 1024: 未加入書架

  // 所有可以從書源轉換的書籍類型 (text | image | audio | webFile)
  static const int allBookType = text | image | audio | webFile;

  // 所有本地書籍類型的聯集
  static const int allBookTypeLocal = text | image | audio | webFile | local;
  
  // 特殊識別標籤
  static const String localTag = "loc_book";
  static const String webDavTag = "webDav::";
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
