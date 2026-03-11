/// Bookmark - 書籤模型
/// 對應 Android: data/entities/Bookmark.kt
class Bookmark {
  int? id;
  final int time;
  final String bookName;
  final String bookAuthor;
  int chapterIndex;
  int chapterPos;
  String chapterName;
  String bookUrl;
  String content;

  Bookmark({
    this.id,
    required this.time,
    this.bookName = "",
    this.bookAuthor = "",
    this.chapterIndex = 0,
    this.chapterPos = 0,
    this.chapterName = "",
    this.bookUrl = "",
    this.content = "",
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'time': time,
      'bookName': bookName,
      'bookAuthor': bookAuthor,
      'chapterIndex': chapterIndex,
      'chapterPos': chapterPos,
      'chapterName': chapterName,
      'bookUrl': bookUrl,
      'content': content,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      time: json['time'] ?? DateTime.now().millisecondsSinceEpoch,
      bookName: json['bookName'] ?? "",
      bookAuthor: json['bookAuthor'] ?? "",
      chapterIndex: json['chapterIndex'] ?? 0,
      chapterPos: json['chapterPos'] ?? 0,
      chapterName: json['chapterName'] ?? "",
      bookUrl: json['bookUrl'] ?? "",
      content: json['content'] ?? "",
    );
  }
}
