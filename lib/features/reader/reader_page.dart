import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import 'engine/page_view_widget.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/models/bookmark.dart';
import '../../core/database/dao/bookmark_dao.dart';
import '../../core/services/dictionary_service.dart';
import '../../shared/theme/app_theme.dart';
import '../settings/font_manager_page.dart';
import '../settings/settings_page.dart';
import '../replace_rule/replace_rule_page.dart';

class ReaderPage extends StatefulWidget {
  final Book book;
  final int chapterIndex;
  final int chapterPos;

  const ReaderPage({
    super.key, 
    required this.book, 
    this.chapterIndex = 0,
    this.chapterPos = 0,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedText = "";
  bool? _lastShowControls;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.chapterPos);
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

  void _updateSystemUI(bool show) {
    if (_lastShowControls == show) return;
    _lastShowControls = show;
    if (show) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => ReaderProvider(
            book: widget.book,
            chapterIndex: widget.chapterIndex,
            chapterPos: widget.chapterPos,
          ),
      child: Consumer<ReaderProvider>(
        builder: (context, provider, child) {
          final theme = provider.currentTheme;
          _updateSystemUI(provider.showControls);

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: theme.backgroundColor,
            drawer: _buildChaptersDrawer(context, provider),
            body: Stack(
              children: [
                // 點擊區域：中央喚出控制項，兩側翻頁
                GestureDetector(
                  onTapUp: (details) {
                    final width = MediaQuery.of(context).size.width;
                    final x = details.globalPosition.dx;
                    
                    // 如果選單已經開啟，點擊任何非工具列區域都應該關閉選單
                    if (provider.showControls) {
                      provider.toggleControls();
                      return;
                    }

                    if (x > width * 0.3 && x < width * 0.7) {
                      provider.toggleControls();
                    } else if (x <= width * 0.3) {
                      if (provider.currentPageIndex > 0) {
                        if (provider.pageTurnMode == 1) {
                          _pageController.jumpToPage(provider.currentPageIndex - 1);
                        } else {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          );
                        }
                      } else {
                        provider.prevChapter();
                      }
                    } else {
                      if (provider.currentPageIndex <
                          provider.pages.length - 1) {
                        if (provider.pageTurnMode == 1) {
                          _pageController.jumpToPage(provider.currentPageIndex + 1);
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          );
                        }
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

                // 頂部工具列 (帶動畫)
                _buildTopBar(context, provider),

                // 側邊亮度條 (帶動畫)
                _buildBrightnessBar(context, provider),

                // 底部工具列 (帶動畫)
                _buildBottomBar(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ReaderProvider provider, ReadingTheme theme) {
    if (provider.isLoading || provider.pages.isEmpty) {
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

    final isVertical = provider.pageTurnMode == 2;

    return Stack(
      children: [
        SelectionArea(
          onSelectionChanged: (content) {
            _selectedText = content?.plainText ?? "";
          },
          contextMenuBuilder: (context, selectableRegionState) {
            return AdaptiveTextSelectionToolbar.buttonItems(
              anchors: selectableRegionState.contextMenuAnchors,
              buttonItems: [
                ...selectableRegionState.contextMenuButtonItems,
                if (_selectedText.isNotEmpty) ...[
                  if (num.tryParse(_selectedText) == null)
                    ContextMenuButtonItem(
                      label: '查詞',
                      onPressed: () {
                        selectableRegionState.hideToolbar();
                        DictionaryService().lookup(_selectedText);
                      },
                    ),
                  ContextMenuButtonItem(
                    label: '筆記',
                    onPressed: () {
                      selectableRegionState.hideToolbar();
                      _showAnnotationDialog(context, provider, _selectedText);
                    },
                  ),
                ],
              ],
            );
          },
          child: PageView.builder(
            controller: _pageController,
            physics: provider.showControls ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
            scrollDirection: isVertical ? Axis.vertical : Axis.horizontal,
            itemCount: provider.pages.length,
            onPageChanged: provider.onPageChanged,
            itemBuilder: (context, index) {
              return PageViewWidget(
                page: provider.pages[index],
                contentStyle: contentStyle,
                titleStyle: titleStyle,
              );
            },
          ),
        ),
        if (provider.brightness < 1.0)
          IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: 1.0 - provider.brightness),
            ),
          ),
      ]
    );
  }

  void _showAnnotationDialog(BuildContext context, ReaderProvider provider, String selectedText) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增筆記'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('原文: "$selectedText"', 
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '輸入筆記內容...'),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              final bookmark = Bookmark(
                time: DateTime.now().millisecondsSinceEpoch,
                bookName: provider.book.name,
                bookAuthor: provider.book.author,
                bookUrl: provider.book.bookUrl,
                chapterIndex: provider.currentChapterIndex,
                chapterPos: provider.currentPageIndex,
                chapterName: provider.currentChapter?.title ?? "",
                bookText: selectedText,
                content: controller.text,
              );
              await BookmarkDao().insert(bookmark);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('筆記已儲存')));
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ReaderProvider provider) {
    final topPadding = MediaQuery.of(context).padding.top;
    final topBarHeight = topPadding + kToolbarHeight;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: provider.showControls ? 0 : -topBarHeight,
      left: 0,
      right: 0,
      child: Container(
        height: topBarHeight,
        color: Colors.black.withValues(alpha: 0.9),
        padding: EdgeInsets.only(top: topPadding),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.book.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    provider.currentChapter?.title ?? "",
                    style: const TextStyle(color: Colors.white70, fontSize: 12, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            if (provider.book.origin != "local")
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton(
                  onPressed: () {
                    // 原版點擊書源名稱會彈出選單
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Text(
                    provider.book.origin.length > 10 
                        ? provider.book.origin.substring(0, 10) 
                        : provider.book.origin,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrightnessBar(BuildContext context, ReaderProvider provider) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      left: provider.showControls ? 16 : -60,
      top: MediaQuery.of(context).size.height * 0.25,
      bottom: MediaQuery.of(context).size.height * 0.35,
      child: Container(
        width: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Icon(Icons.brightness_7, color: Colors.white, size: 20),
            ),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: provider.brightness,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (v) => provider.setBrightness(v),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Icon(Icons.brightness_4, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, ReaderProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('正文搜尋'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '輸入搜尋關鍵字 (僅限已快取章節)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final keyword = controller.text;
              if (keyword.isNotEmpty) {
                Navigator.pop(context);
                _doSearch(context, provider, keyword);
              }
            },
            child: const Text('搜尋'),
          ),
        ],
      ),
    );
  }

  void _doSearch(BuildContext context, ReaderProvider provider, String keyword) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final results = await provider.searchContent(keyword);
    if (!context.mounted) return;
    Navigator.pop(context); // Close loading

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('搜尋結果: "$keyword" (${results.length})', 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: results.isEmpty 
                ? const Center(child: Text('未找到結果'))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final res = results[index];
                      return ListTile(
                        title: Text(res['chapterTitle'] ?? ""),
                        subtitle: Text(res['snippet'] ?? "", maxLines: 2),
                        onTap: () {
                          provider.loadChapter(res['chapterIndex']);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ReaderProvider provider) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // 計算底部選單高度：懸浮按鈕排 + 進度條排 + 按鈕導覽排
    final bottomBarHeight = 160.0 + bottomPadding;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: provider.showControls ? 0 : -bottomBarHeight,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 懸浮按鈕排 (仿原版 FloatingActionButton 排列)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniFab(Icons.search, () => _showSearchDialog(context, provider)),
                _buildMiniFab(
                  provider.isAutoPaging ? Icons.pause_circle_filled : Icons.auto_stories, 
                  () {
                    provider.toggleAutoPage();
                    provider.toggleControls(); // 關閉工具列以沉浸閱讀
                  },
                ),
                _buildMiniFab(Icons.find_replace, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReplaceRulePage()),
                  );
                }),
                _buildMiniFab(
                  provider.themeIndex == 1 ? Icons.brightness_7 : Icons.brightness_2, 
                  () => provider.setTheme(provider.themeIndex == 1 ? 0 : 1)
                ),
              ],
            ),
          ),
          
          Container(
            color: Colors.black.withValues(alpha: 0.9),
            padding: EdgeInsets.fromLTRB(16, 5, 16, bottomPadding + 5),
            child: Column(
              children: [
                // 翻頁/進度條
                Row(
                  children: [
                    TextButton(
                      onPressed: () => provider.prevChapter(),
                      child: const Text("上一章", style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    Expanded(
                      child: Slider(
                        value: provider.currentChapterIndex.toDouble(),
                        min: 0,
                        max: (provider.chapters.length - 1).clamp(0, 9999).toDouble(),
                        onChanged: (v) => provider.loadChapter(v.toInt()),
                      ),
                    ),
                    TextButton(
                      onPressed: () => provider.nextChapter(),
                      child: const Text("下一章", style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildIconButton(Icons.toc, "目錄", () {
                      provider.toggleControls();
                      _scaffoldKey.currentState?.openDrawer();
                    }),
                    GestureDetector(
                      onLongPress: () => _showTtsSettingsPanel(context, provider),
                      child: _buildIconButton(
                        provider.tts.isPlaying || provider.httpTts.isPlaying ? Icons.stop : Icons.record_voice_over, 
                        "朗讀", 
                        () => provider.toggleTts()
                      ),
                    ),
                    _buildIconButton(Icons.text_format, "界面", () {
                      _showSettingsPanel(context, provider);
                    }),
                    _buildIconButton(Icons.settings, "設定", () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTtsSettingsPanel(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) {
        return Consumer<ReaderProvider>(
          builder: (context, provider, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("朗讀引擎", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("系統 TTS"),
                        selected: provider.ttsMode == 0,
                        onSelected: (v) => provider.setTtsMode(0),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("HTTP TTS"),
                        selected: provider.ttsMode == 1,
                        onSelected: (v) => provider.setTtsMode(1),
                      ),
                    ],
                  ),
                  if (provider.ttsMode == 1) ...[
                    const SizedBox(height: 20),
                    const Text("選擇 HTTP 引擎", style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 10),
                    provider.httpTtsEngines.isEmpty 
                      ? const Text("未找到 HTTP TTS 引擎，請先匯入", style: TextStyle(color: Colors.grey, fontSize: 12))
                      : SizedBox(
                          height: 150,
                          child: ListView.builder(
                            itemCount: provider.httpTtsEngines.length,
                            itemBuilder: (context, index) {
                              final engine = provider.httpTtsEngines[index];
                              return ListTile(
                                title: Text(engine.name, style: const TextStyle(color: Colors.white)),
                                trailing: provider.selectedHttpTtsId == engine.id 
                                  ? const Icon(Icons.check, color: Colors.blue) 
                                  : null,
                                onTap: () => provider.setSelectedHttpTts(engine.id),
                              );
                            },
                          ),
                        ),
                  ],
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("確定"),
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

  Widget _buildMiniFab(IconData icon, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildChaptersDrawer(BuildContext context, ReaderProvider provider) {
    return _ChaptersDrawer(
      chapters: provider.chapters,
      currentChapterIndex: provider.currentChapterIndex,
      theme: provider.currentTheme,
      onChapterTap: (index) {
        provider.loadChapter(index);
      },
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("閱讀字體", style: TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FontManagerPage()),
                          );
                        },
                        child: Text(
                          provider.fontFamily ?? "系統預設",
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  const Text("翻頁方式", style: TextStyle(color: Colors.white)),
                  Wrap(
                    spacing: 8.0,
                    alignment: WrapAlignment.spaceEvenly,
                    children: [
                      ChoiceChip(
                        label: const Text('水平平滑'),
                        selected: provider.pageTurnMode == 0,
                        onSelected: (v) { if (v) provider.setPageTurnMode(0); },
                      ),
                      ChoiceChip(
                        label: const Text('直接覆蓋'),
                        selected: provider.pageTurnMode == 1,
                        onSelected: (v) { if (v) provider.setPageTurnMode(1); },
                      ),
                      ChoiceChip(
                        label: const Text('垂直平滑'),
                        selected: provider.pageTurnMode == 2,
                        onSelected: (v) { if (v) provider.setPageTurnMode(2); },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text("亮度調節", style: TextStyle(color: Colors.white)),
                  Slider(
                    value: provider.brightness,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (v) => provider.setBrightness(v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("繁簡轉換", style: TextStyle(color: Colors.white)),
                      Switch(
                        value: provider.chineseConvert,
                        onChanged: (v) => provider.setChineseConvert(v),
                      ),
                    ],
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

class _ChaptersDrawer extends StatefulWidget {
  final List<BookChapter> chapters;
  final int currentChapterIndex;
  final ReadingTheme theme;
  final Function(int) onChapterTap;

  const _ChaptersDrawer({
    required this.chapters,
    required this.currentChapterIndex,
    required this.theme,
    required this.onChapterTap,
  });

  @override
  State<_ChaptersDrawer> createState() => _ChaptersDrawerState();
}

class _ChaptersDrawerState extends State<_ChaptersDrawer> {
  late TextEditingController _searchController;
  List<int> _filteredIndices = [];
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredIndices = List.generate(widget.chapters.length, (i) => i);
    _scrollController = ScrollController(
      initialScrollOffset:
          (widget.currentChapterIndex * 50.0).clamp(0, double.infinity),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filterChapters(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIndices = List.generate(widget.chapters.length, (i) => i);
      } else {
        _filteredIndices = [];
        for (int i = 0; i < widget.chapters.length; i++) {
          if (widget.chapters[i].title
              .toLowerCase()
              .contains(query.toLowerCase())) {
            _filteredIndices.add(i);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: widget.theme.backgroundColor,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              bottom: 10,
            ),
            color: widget.theme.backgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "目錄",
                      style: TextStyle(
                        color: widget.theme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${widget.chapters.length} 章",
                      style: TextStyle(
                        color: widget.theme.textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: widget.theme.textColor),
                  decoration: InputDecoration(
                    hintText: "搜尋章節...",
                    hintStyle: TextStyle(
                      color: widget.theme.textColor.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: widget.theme.textColor.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: widget.theme.textColor.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: _filterChapters,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: widget.theme.textColor.withValues(alpha: 0.1),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: _filteredIndices.length,
              itemBuilder: (context, index) {
                final realIndex = _filteredIndices[index];
                final chapter = widget.chapters[realIndex];
                final isCurrent = widget.currentChapterIndex == realIndex;

                return ListTile(
                  dense: true,
                  title: Text(
                    chapter.title,
                    style: TextStyle(
                      color: isCurrent ? Colors.blue : widget.theme.textColor,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    widget.onChapterTap(realIndex);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
