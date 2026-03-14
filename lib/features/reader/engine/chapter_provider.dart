import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'text_page.dart';

class ChapterProvider {
  // 避頭點：不能出現在行首的符號
  static const String _lineStartForbidden = "。，、：；！？）》」』〉】〗;:!?)]}>";
  // 避尾點：不能出現在行尾的符號
  static const String _lineEndForbidden = "（《「『〈【〖([{<";

  static List<TextPage> paginate({
    required String content,
    required BookChapter chapter,
    required int chapterIndex,
    required int chapterSize,
    required Size viewSize,
    required TextStyle titleStyle,
    required TextStyle contentStyle,
    double paragraphSpacing = 1.0,
    int textIndent = 2,
    double titleTopSpacing = 0.0,
    double titleBottomSpacing = 10.0,
    bool textFullJustify = true,
    double padding = 16.0,
  }) {
    final double width = viewSize.width - (padding * 2);
    final double height = viewSize.height - 80;

    final List<TextPage> pages = [];
    final List<String> currentLines = [];
    double currentHeight = 0;

    final titlePainter = TextPainter(
      text: TextSpan(text: chapter.title, style: titleStyle),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );
    titlePainter.layout(maxWidth: width);
    currentHeight += titleTopSpacing + titlePainter.height + titleBottomSpacing;
    currentLines.add("TITLE:${chapter.title}");

    final paragraphs = content.split('\n');
    final indent = "　" * textIndent;

    for (var p in paragraphs) {
      if (p.trim().isEmpty) continue;
      String text = indent + p.trim();
      
      int start = 0;
      while (start < text.length) {
        final tp = TextPainter(
          text: TextSpan(text: text.substring(start), style: contentStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: width);
        
        int end = tp.getPositionForOffset(Offset(width, 0)).offset;
        if (end <= 0) break;

        if (start + end < text.length) {
          String nextChar = text.substring(start + end, start + end + 1);
          if (_lineStartForbidden.contains(nextChar) && end > 1) {
            end--;
          }
        }
        
        if (end > 0) {
          String lastChar = text.substring(start + end - 1, start + end);
          if (_lineEndForbidden.contains(lastChar) && end > 1) {
            end--;
          }
        }

        currentLines.add(text.substring(start, start + end));
        start += end;
        currentHeight += tp.preferredLineHeight * (contentStyle.height ?? 1.5);

        if (currentHeight >= height) {
          pages.add(TextPage(
            index: pages.length, pageSize: 0,
            lines: List.from(currentLines),
            title: chapter.title, chapterIndex: chapterIndex, chapterSize: chapterSize,
          ));
          currentLines.clear();
          currentHeight = 0;
        }
      }
      currentHeight += (contentStyle.fontSize ?? 18) * paragraphSpacing;
    }

    if (currentLines.isNotEmpty) {
      pages.add(TextPage(
        index: pages.length, pageSize: 0,
        lines: List.from(currentLines),
        title: chapter.title, chapterIndex: chapterIndex, chapterSize: chapterSize,
      ));
    }

    return pages.asMap().entries.map((e) => e.value.copyWith(index: e.key, pageSize: pages.length)).toList();
  }
}
