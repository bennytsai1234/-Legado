import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../reader_provider.dart';
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
    // 監聽 Provider 中的自動翻頁進度
    final provider = context.watch<ReaderProvider>();

    return CustomPaint(
      size: Size.infinite,
      painter: _TextPagePainter(
        page: page,
        contentStyle: contentStyle,
        titleStyle: titleStyle,
        currentTime: DateFormat('HH:mm').format(DateTime.now()),
        batteryLevel: provider.batteryLevel,
        isAutoPaging: provider.isAutoPaging,
        autoPageProgress: provider.autoPageProgress,
        accentColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _TextPagePainter extends CustomPainter {
  final TextPage page;
  final TextStyle contentStyle;
  final TextStyle titleStyle;
  final String currentTime;
  final int batteryLevel;
  final bool isAutoPaging;
  final double autoPageProgress;
  final Color accentColor;

  _TextPagePainter({
    required this.page,
    required this.contentStyle,
    required this.titleStyle,
    required this.currentTime,
    required this.batteryLevel,
    required this.isAutoPaging,
    required this.autoPageProgress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 處理自動翻頁剪裁 (高度還原 Android 覆蓋模式)
    if (isAutoPaging && autoPageProgress > 0) {
      _drawAutoPageLine(canvas, size);
      // 這裡僅繪製進度線以下的內容 (模擬 Android clipRect)
      canvas.clipRect(Rect.fromLTWH(0, size.height * autoPageProgress, size.width, size.height));
    }

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

  /// 繪製自動翻頁進度線 (高度還原 Android AutoPager)
  void _drawAutoPageLine(Canvas canvas, Size size) {
    final double y = size.height * autoPageProgress;
    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  void _drawHeaderFooter(Canvas canvas, Size size) {
    final paintColor = contentStyle.color?.withValues(alpha: 0.5) ?? Colors.grey;
    final textStyle = TextStyle(color: paintColor, fontSize: 12.0);

    // 1. Header: Chapter Title (頂部左側)
    if (page.title.isNotEmpty) {
      final titleSpan = TextSpan(text: page.title, style: textStyle);
      final tp = TextPainter(
        text: titleSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      tp.layout(maxWidth: size.width - 32);
      tp.paint(canvas, const Offset(16.0, 12.0));
    }

    // 2. Footer: Left - Time (底部左側)
    final timeSpan = TextSpan(text: currentTime, style: textStyle);
    final timeTp = TextPainter(text: timeSpan, textDirection: TextDirection.ltr);
    timeTp.layout();
    timeTp.paint(canvas, Offset(16.0, size.height - 24.0));

    // 3. Footer: Right - Progress + Battery (底部右側)
    final progressStr = page.readProgress;
    final footerSpan = TextSpan(text: "$progressStr  ", style: textStyle);
    final footerTp = TextPainter(text: footerSpan, textDirection: TextDirection.ltr);
    footerTp.layout();
    
    final footerX = size.width - 16.0 - 25.0 - footerTp.width; // 25.0 為預留給電池的寬度
    footerTp.paint(canvas, Offset(footerX, size.height - 24.0));

    _drawBattery(canvas, Offset(size.width - 36.0, size.height - 21.0), paintColor);
  }

  /// 繪製電池圖示 (高度還原 Android BatteryView)
  void _drawBattery(Canvas canvas, Offset offset, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 電池主體矩形 (20x10)
    final Rect body = Rect.fromLTWH(offset.dx, offset.dy, 20, 10);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(2)), paint);

    // 電池正極 (小突起)
    final Paint polarPaint = Paint()..color = color..style = PaintingStyle.fill;
    final Rect polar = Rect.fromLTWH(offset.dx + 20, offset.dy + 3, 2, 4);
    canvas.drawRect(polar, polarPaint);

    // 內部電量填滿
    final double levelWidth = (18 * (batteryLevel / 100)).clamp(0, 18);
    final Rect level = Rect.fromLTWH(offset.dx + 1, offset.dy + 1, levelWidth, 8);
    canvas.drawRect(level, polarPaint);
  }

  @override
  bool shouldRepaint(covariant _TextPagePainter oldDelegate) {
    return oldDelegate.page != page ||
        oldDelegate.contentStyle != contentStyle ||
        oldDelegate.titleStyle != titleStyle ||
        oldDelegate.currentTime != currentTime ||
        oldDelegate.batteryLevel != batteryLevel ||
        oldDelegate.isAutoPaging != isAutoPaging ||
        oldDelegate.autoPageProgress != autoPageProgress;
  }
}
