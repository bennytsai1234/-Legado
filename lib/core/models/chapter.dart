/// BookChapter - 章節模型
/// 對應 Android: data/entities/BookChapter.kt
library;

class BookChapter {
  String url; // 章節 URL
  String title; // 章節名稱
  String bookUrl; // 所屬書籍 URL
  int index; // 章節索引
  bool isVolume; // 是否為卷標題
  bool isVip; // 是否 VIP
  bool isPay; // 是否付費
  String? resourceUrl; // 音頻/圖片資源 URL
  String? tag; // 來源標記
  String? variable; // 暫存變數
  int startFragmentId; // 分段起始 ID
  int endFragmentId; // 分段結束 ID

  BookChapter({
    required this.url,
    required this.title,
    required this.bookUrl,
    required this.index,
    this.isVolume = false,
    this.isVip = false,
    this.isPay = false,
    this.resourceUrl,
    this.tag,
    this.variable,
    this.startFragmentId = 0,
    this.endFragmentId = 0,
  });

  factory BookChapter.fromJson(Map<String, dynamic> json) {
    return BookChapter(
      url: json['url'] ?? '',
      title: json['title'] ?? '',
      bookUrl: json['bookUrl'] ?? '',
      index: json['index'] ?? 0,
      isVolume: json['isVolume'] ?? false,
      isVip: json['isVip'] ?? false,
      isPay: json['isPay'] ?? false,
      resourceUrl: json['resourceUrl'],
      tag: json['tag'],
      variable: json['variable'],
      startFragmentId: json['startFragmentId'] ?? 0,
      endFragmentId: json['endFragmentId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        'bookUrl': bookUrl,
        'index': index,
        'isVolume': isVolume,
        'isVip': isVip,
        'isPay': isPay,
        'resourceUrl': resourceUrl,
        'tag': tag,
        'variable': variable,
        'startFragmentId': startFragmentId,
        'endFragmentId': endFragmentId,
      };
}
