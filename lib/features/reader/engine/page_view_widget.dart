import 'package:flutter/material.dart';
import 'text_page.dart';
import 'chapter_provider.dart';

/// PageViewWidget - 單頁文字繪製視圖
/// 對應 Android: ui/book/read/page/PageView.kt 與 ContentTextView.kt
class PageViewWidget extends StatelessWidget {
  final TextPage page;
  final TextStyle contentStyle;
  final TextStyle titleStyle;

  const PageViewWidget({
    super.key,
    required this.page,
    required this.contentStyle,
    required this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _TextPagePainter(
        page: page,
        contentStyle: contentStyle,
        titleStyle: titleStyle,
      ),
    );
  }
}

class _TextPagePainter extends CustomPainter {
  final TextPage page;
  final TextStyle contentStyle;
  final TextStyle titleStyle;

  _TextPagePainter({
    required this.page,
    required this.contentStyle,
    required this.titleStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double paddingLeft = ChapterProvider.paddingLeft;
    final double paddingTop = ChapterProvider.paddingTop;

    for (final line in page.lines) {
      final style = line.isTitle ? titleStyle : contentStyle;
      final textSpan = TextSpan(text: line.text, style: style);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final offset = Offset(paddingLeft, paddingTop + line.lineTop);
      textPainter.paint(canvas, offset);
    }

    // 繪製頂部及底部狀態列 (章節標題、進度、時間等)
    _drawHeaderFooter(canvas, size);
  }

  void _drawHeaderFooter(Canvas canvas, Size size) {
    final paintColor =
        contentStyle.color?.withValues(alpha: 0.5) ?? Colors.grey;

    final textStyle = TextStyle(color: paintColor, fontSize: 12.0);

    // Header: Title
    if (page.title.isNotEmpty) {
      final titleSpan = TextSpan(text: page.title, style: textStyle);
      final tp = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      tp.layout(maxWidth: size.width - 32);
      tp.paint(canvas, const Offset(16.0, 16.0));
    }

    // Footer: Progress + Battery / Time
    final progressStr = page.readProgress;
    final footerSpan = TextSpan(text: progressStr, style: textStyle);
    final footerTp = TextPainter(
      text: footerSpan,
      textDirection: TextDirection.ltr,
    );
    footerTp.layout();
    footerTp.paint(
      canvas,
      Offset(size.width - 16.0 - footerTp.width, size.height - 24.0),
    );

    // TODO: Draw Battery and System Time
  }

  @override
  bool shouldRepaint(covariant _TextPagePainter oldDelegate) {
    return oldDelegate.page != page ||
        oldDelegate.contentStyle != contentStyle ||
        oldDelegate.titleStyle != titleStyle;
  }
}
