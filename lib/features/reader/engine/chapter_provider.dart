import 'package:flutter/material.dart';
import '../../../core/models/chapter.dart';
import 'text_page.dart';

/// ChapterProvider - 章節排版引擎
/// 將長篇文字切割為多個 TextPage 供 PageView 顯示
/// 對應 Android: ui/book/read/page/provider/ChapterProvider.kt
class ChapterProvider {
  static const double paddingTop = 40.0;
  static const double paddingBottom = 40.0;
  static const double paddingLeft = 16.0;
  static const double paddingRight = 16.0;

  /// 排版並切割章節內容
  static List<TextPage> paginate({
    required String content,
    required BookChapter chapter,
    required int chapterIndex,
    required int chapterSize,
    required Size viewSize,
    required TextStyle titleStyle,
    required TextStyle contentStyle,
    double paragraphSpacing = 16.0,
  }) {
    final List<TextPage> pages = [];
    final double visibleWidth = viewSize.width - paddingLeft - paddingRight;
    final double visibleHeight = viewSize.height - paddingTop - paddingBottom;

    if (visibleWidth <= 0 || visibleHeight <= 0) return pages;

    final paragraphs = content.split('\n');
    List<TextLine> currentLines = [];
    double currentHeight = 0.0;
    int pageIndex = 0;
    int chapterPosition = 0;
    int paragraphNum = 0;

    // TODO: Draw Chapter Title on the first page
    // Here we simplified that the chapter title is already in the content string by ContentProcessor
    
    for (int pIndex = 0; pIndex < paragraphs.length; pIndex++) {
      String paraText = paragraphs[pIndex];
      paragraphNum++;
      
      if (paraText.isEmpty) {
         // handle empty paragraph as spacing
         currentHeight += paragraphSpacing;
         chapterPosition += 1;
         continue;
      }

      // Check if it's the title (usually the first paragraph if ContentProcessor included it)
      bool isTitle = (pIndex == 0 && paraText == chapter.title);
      TextStyle style = isTitle ? titleStyle : contentStyle;

      // layout text by wrapping
      TextPainter textPainter = TextPainter(
        text: TextSpan(text: paraText, style: style),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout(maxWidth: visibleWidth);

      final lineMetrics = textPainter.computeLineMetrics();
      
      int currentLineStartIndex = 0;
      
      for (int i = 0; i < lineMetrics.length; i++) {
        final metric = lineMetrics[i];
        final lineHeight = metric.height;
        
        // Calculate chars in this line based on textPainter's Position
        // Note: Flutter's standard TextPainter doesn't yield exact char slices per line metrics easily
        // We use getPositionForOffset to approximate, or better use TextPainter.getPositionForOffset()
        
        // A more reliable way in Flutter to get substring per line:
        // We find the text offset for the end of the line
        int charEnd = paraText.length;
        if (i < lineMetrics.length - 1) {
            // Find the character index where the line breaks
            final nextLineOffset = Offset(0, metric.baseline + metric.descent + 1); // just below this line
            TextPosition endPos = textPainter.getPositionForOffset(nextLineOffset);
            charEnd = endPos.offset;
        }
        
        String lineText = paraText.substring(currentLineStartIndex, charEnd);
        bool isParaEnd = (i == lineMetrics.length - 1);
        
        // Check if page breaks
        if (currentHeight + lineHeight > visibleHeight && currentLines.isNotEmpty) {
           pages.add(TextPage(
             index: pageIndex++,
             lines: List.from(currentLines),
             title: chapter.title,
             chapterIndex: chapterIndex,
             chapterSize: chapterSize,
           ));
           currentLines.clear();
           currentHeight = 0.0;
        }

        currentLines.add(TextLine(
          text: lineText,
          width: metric.width,
          height: lineHeight,
          isTitle: isTitle,
          isParagraphEnd: isParaEnd,
          chapterPosition: chapterPosition + currentLineStartIndex,
          lineTop: currentHeight,
          lineBottom: currentHeight + lineHeight,
          paragraphNum: paragraphNum,
        ));

        currentHeight += lineHeight;
        currentLineStartIndex = charEnd;
      }
      
      currentHeight += paragraphSpacing;
      // account for newline character length
      chapterPosition += paraText.length + 1;
    }

    if (currentLines.isNotEmpty) {
      pages.add(TextPage(
        index: pageIndex++,
        lines: List.from(currentLines),
        title: chapter.title,
        chapterIndex: chapterIndex,
        chapterSize: chapterSize,
      ));
    }
    
    // Update pageSize for all pages
    for (var page in pages) {
      // Dart doesn't allow mutating final fields directly in the constructor, 
      // but conceptually we would want pageSize injected. 
      // We should ideally create them with pageSize known, or we can just calculate read progress locally.
      // Since Dart doesn't have data classes copy with ease without external packages, we will just rebuild the list.
    }
    
    // Re-assign with pageSize populated
    final List<TextPage> result = [];
    for (int i = 0; i < pages.length; i++) {
        result.add(TextPage(
            index: pages[i].index,
            lines: pages[i].lines,
            title: pages[i].title,
            chapterIndex: pages[i].chapterIndex,
            chapterSize: pages[i].chapterSize,
            pageSize: pages.length,
        ));
    }

    return result;
  }
}
