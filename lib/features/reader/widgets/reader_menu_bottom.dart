import 'package:flutter/material.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';

class ReaderMenuBottom extends StatelessWidget {
  final ReaderProvider provider;
  final VoidCallback onOpenDrawer;
  final VoidCallback onPageTurnMode;
  final VoidCallback onTypography;
  final VoidCallback onTheme;

  const ReaderMenuBottom({
    super.key,
    required this.provider,
    required this.onOpenDrawer,
    required this.onPageTurnMode,
    required this.onTypography,
    required this.onTheme,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: provider.showControls ? 0 : -150,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            // 1. 播放/章節 進度條
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  onPressed: provider.prevChapter,
                ),
                Expanded(
                  child: Slider(
                    value: provider.currentChapterIndex.toDouble(),
                    min: 0,
                    max: (provider.chapters.length - 1).toDouble().clamp(0, double.infinity),
                    divisions: (provider.chapters.length - 1).clamp(1, 9999),
                    onChanged: (v) => provider.onScrubbing(v.toInt()),
                    onChangeEnd: (v) => provider.onScrubEnd(v.toInt()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  onPressed: provider.nextChapter,
                ),
              ],
            ),
            // 2. 核心功能按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAction(Icons.list, "目錄", onOpenDrawer),
                _buildAction(Icons.auto_stories, "翻頁", onPageTurnMode),
                _buildAction(Icons.text_fields, "排版", onTypography),
                _buildAction(Icons.color_lens, "主題", onTheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
