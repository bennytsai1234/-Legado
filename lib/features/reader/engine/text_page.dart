/// TextLine - 單行文字資訊
/// 對應 Android: ui/book/read/page/entities/TextLine.kt
class TextLine {
  final String text;
  final double width;
  final double height;
  final bool isTitle;
  final bool isParagraphEnd;
  final int chapterPosition;
  final double lineTop;
  final double lineBottom;
  final int paragraphNum;

  TextLine({
    required this.text,
    required this.width,
    required this.height,
    this.isTitle = false,
    this.isParagraphEnd = false,
    this.chapterPosition = 0,
    this.lineTop = 0,
    this.lineBottom = 0,
    this.paragraphNum = 0,
  });
}

/// TextPage - 單頁文字資訊
/// 對應 Android: ui/book/read/page/entities/TextPage.kt
class TextPage {
  final int index;
  final List<TextLine> lines;
  final String title;
  final int chapterIndex;
  final int chapterSize; // 總章節數
  final int pageSize; // 本章總頁數

  TextPage({
    required this.index,
    required this.lines,
    required this.title,
    required this.chapterIndex,
    this.chapterSize = 0,
    this.pageSize = 0,
  });

  int get lineSize => lines.length;

  String get readProgress {
    if (chapterSize == 0 || (pageSize == 0 && chapterIndex == 0)) {
      return "0.0%";
    } else if (pageSize == 0) {
      return "${((chapterIndex + 1.0) / chapterSize * 100).toStringAsFixed(1)}%";
    }
    double percent =
        (chapterIndex / chapterSize) +
        (1.0 / chapterSize) * (index + 1) / pageSize;
    String formatted = "${(percent * 100).toStringAsFixed(1)}%";
    if (formatted == "100.0%" &&
        (chapterIndex + 1 != chapterSize || index + 1 != pageSize)) {
      formatted = "99.9%";
    }
    return formatted;
  }

  TextPage copyWith({
    int? index,
    List<TextLine>? lines,
    String? title,
    int? chapterIndex,
    int? chapterSize,
    int? pageSize,
  }) {
    return TextPage(
      index: index ?? this.index,
      lines: lines ?? this.lines,
      title: title ?? this.title,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chapterSize: chapterSize ?? this.chapterSize,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
