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
  String bookText;
  String content;

  Bookmark({
    this.id,
    required this.time,
    this.bookName = "",
    this.bookAuthor = "",
    this.chapterIndex = 0,
    this.chapterPos = 0,
    this.chapterName = "",
    this.bookText = "",
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
      'bookText': bookText,
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
      bookText: json['bookText'] ?? "",
      content: json['content'] ?? "",
    );
  }
}
