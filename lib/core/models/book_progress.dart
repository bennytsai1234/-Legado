/// BookProgress - 閱讀進度模型
/// 對應 Android: data/entities/BookProgress.kt
class BookProgress {
  final String name;
  final String author;
  final int durChapterIndex;
  final int durChapterPos;
  final int durChapterTime;
  final String? durChapterTitle;

  BookProgress({
    required this.name,
    required this.author,
    required this.durChapterIndex,
    required this.durChapterPos,
    required this.durChapterTime,
    this.durChapterTitle,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'author': author,
      'durChapterIndex': durChapterIndex,
      'durChapterPos': durChapterPos,
      'durChapterTime': durChapterTime,
      'durChapterTitle': durChapterTitle,
    };
  }

  factory BookProgress.fromJson(Map<String, dynamic> json) {
    return BookProgress(
      name: json['name'] ?? "",
      author: json['author'] ?? "",
      durChapterIndex: json['durChapterIndex'] ?? 0,
      durChapterPos: json['durChapterPos'] ?? 0,
      durChapterTime: json['durChapterTime'] ?? 0,
      durChapterTitle: json['durChapterTitle'],
    );
  }
}
