import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import '../../core/models/book.dart';
import '../../shared/theme/app_theme.dart';
import 'engine/page_view_widget.dart';

class ReaderPage extends StatefulWidget {
  final Book book;
  final int chapterIndex;

  const ReaderPage({super.key, required this.book, this.chapterIndex = 0});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // 進入閱讀器時隱藏系統狀態列
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // 退出時恢復系統狀態列
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => ReaderProvider(
            book: widget.book,
            chapterIndex: widget.chapterIndex,
          ),
      child: Consumer<ReaderProvider>(
        builder: (context, provider, child) {
          final theme = provider.currentTheme;

          return Scaffold(
            backgroundColor: theme.backgroundColor,
            body: Stack(
              children: [
                // 點擊區域：中央喚出控制項，兩側翻頁
                GestureDetector(
                  onTapUp: (details) {
                    final width = MediaQuery.of(context).size.width;
                    final x = details.globalPosition.dx;
                    if (x > width * 0.3 && x < width * 0.7) {
                      provider.toggleControls();
                    } else if (x <= width * 0.3) {
                      if (provider.currentPageIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        provider.prevChapter();
                      }
                    } else {
                      if (provider.currentPageIndex <
                          provider.pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        provider.nextChapter();
                      }
                    }
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 0 &&
                          constraints.maxHeight > 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          provider.updateViewSize(
                            Size(constraints.maxWidth, constraints.maxHeight),
                          );
                        });
                      }
                      return _buildContent(provider, theme);
                    },
                  ),
                ),

                // 頂部工具列
                if (provider.showControls) _buildTopBar(context, provider),

                // 底部工具列
                if (provider.showControls) _buildBottomBar(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ReaderProvider provider, ReadingTheme theme) {
    if (provider.isLoading || provider.pages.isEmpty) {
      // 顯示純文字載入或空內容
      return Center(
        child:
            provider.isLoading
                ? const CircularProgressIndicator()
                : Text(
                  "內容為空或解析失敗\n${provider.content}",
                  style: TextStyle(color: theme.textColor),
                  textAlign: TextAlign.center,
                ),
      );
    }

    final titleStyle = TextStyle(
      fontSize: provider.fontSize + 4,
      fontWeight: FontWeight.bold,
      color: theme.textColor,
    );

    final contentStyle = TextStyle(
      fontSize: provider.fontSize,
      height: provider.lineHeight,
      color: theme.textColor,
    );

    return PageView.builder(
      controller: _pageController,
      itemCount: provider.pages.length,
      onPageChanged: provider.onPageChanged,
      itemBuilder: (context, index) {
        return PageViewWidget(
          page: provider.pages[index],
          contentStyle: contentStyle,
          titleStyle: titleStyle,
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, ReaderProvider provider) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.book.name,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                provider.currentChapter?.title ?? "",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ReaderProvider provider) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 進度條
            Row(
              children: [
                const Text(
                  "上一章",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                Expanded(
                  child: Slider(
                    value: provider.currentChapterIndex.toDouble(),
                    min: 0,
                    max:
                        (provider.chapters.length - 1)
                            .clamp(0, 9999)
                            .toDouble(),
                    onChanged: (v) => provider.loadChapter(v.toInt()),
                  ),
                ),
                const Text(
                  "下一章",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            // 功能按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIconButton(Icons.list, "目錄", () {
                  // TODO: 顯示目錄側滑欄
                }),
                _buildIconButton(Icons.settings, "設定", () {
                  _showSettingsPanel(context, provider);
                }),
                ListenableBuilder(
                  listenable: provider.tts,
                  builder: (context, _) {
                    return _buildIconButton(
                      provider.tts.isPlaying ? Icons.stop : Icons.headset, 
                      provider.tts.isPlaying ? "停止朗讀" : "朗讀", 
                      () {
                        provider.toggleTts();
                      }
                    );
                  }
                ),
                _buildIconButton(Icons.brightness_medium, "主題", () {
                  provider.setTheme(provider.themeIndex + 1);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showSettingsPanel(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("字體大小", style: TextStyle(color: Colors.white)),
                  Row(
                    children: [
                      IconButton(
                        onPressed:
                            () => provider.setFontSize(provider.fontSize - 1),
                        icon: const Icon(Icons.remove, color: Colors.white),
                      ),
                      Text(
                        provider.fontSize.toInt().toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        onPressed:
                            () => provider.setFontSize(provider.fontSize + 1),
                        icon: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                  const Text("行間距", style: TextStyle(color: Colors.white)),
                  Slider(
                    value: provider.lineHeight,
                    min: 1.2,
                    max: 2.5,
                    onChanged: (v) => provider.setLineHeight(v),
                  ),
                  const Text("閱讀主題", style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppTheme.readingThemes.length,
                      itemBuilder: (context, index) {
                        final t = AppTheme.readingThemes[index];
                        return GestureDetector(
                          onTap: () => provider.setTheme(index),
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: t.backgroundColor,
                              border: Border.all(
                                color:
                                    provider.themeIndex == index
                                        ? Colors.blue
                                        : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                "文",
                                style: TextStyle(color: t.textColor),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
