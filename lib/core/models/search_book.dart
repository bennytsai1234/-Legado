/// SearchBook - 搜尋結果模型
/// 對應 Android: data/entities/SearchBook.kt
library;

class SearchBook {
  String bookUrl; // 書籍 URL
  String name; // 書名
  String? author; // 作者
  String? kind; // 分類
  String? coverUrl; // 封面 URL
  String? intro; // 簡介
  String? wordCount; // 字數
  String? latestChapterTitle; // 最新章節
  String origin; // 書源 URL
  String? originName; // 書源名稱
  int originOrder; // 書源排序
  int type; // 書源類型
  int addTime; // 添加時間
  String? variable; // 暫存變數

  SearchBook({
    required this.bookUrl,
    required this.name,
    this.author,
    this.kind,
    this.coverUrl,
    this.intro,
    this.wordCount,
    this.latestChapterTitle,
    required this.origin,
    this.originName,
    this.originOrder = 0,
    this.type = 0,
    this.addTime = 0,
    this.variable,
  });

  factory SearchBook.fromJson(Map<String, dynamic> json) {
    return SearchBook(
      bookUrl: json['bookUrl'] ?? '',
      name: json['name'] ?? '',
      author: json['author'],
      kind: json['kind'],
      coverUrl: json['coverUrl'],
      intro: json['intro'],
      wordCount: json['wordCount'],
      latestChapterTitle: json['latestChapterTitle'],
      origin: json['origin'] ?? '',
      originName: json['originName'],
      originOrder: json['originOrder'] ?? 0,
      type: json['type'] ?? 0,
      addTime: json['addTime'] ?? 0,
      variable: json['variable'],
    );
  }

  Map<String, dynamic> toJson() => {
    'bookUrl': bookUrl,
    'name': name,
    'author': author,
    'kind': kind,
    'coverUrl': coverUrl,
    'intro': intro,
    'wordCount': wordCount,
    'latestChapterTitle': latestChapterTitle,
    'origin': origin,
    'originName': originName,
    'originOrder': originOrder,
    'type': type,
    'addTime': addTime,
    'variable': variable,
  };
}

class AggregatedSearchBook {
  final SearchBook book;
  final List<String> sources;

  AggregatedSearchBook({required this.book, required this.sources});
}
