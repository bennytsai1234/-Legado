import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/services/dictionary_service.dart';
import '../../shared/theme/app_theme.dart';
import '../settings/font_manager_page.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedText = "";

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
                if (_selectedText.isNotEmpty &&
                    num.tryParse(_selectedText) == null)
                  ContextMenuButtonItem(
                    label: '查詞',
                    onPressed: () {
                      selectableRegionState.hideToolbar();
                      DictionaryService().lookup(_selectedText);
                    },
                  ),
              ],
            );
          },
          child: PageView.builder(
            controller: _pageController,
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
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _showSearchDialog(context, provider),
            ),
            IconButton(
              icon: Icon(
                provider.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: Colors.white,
              ),
              onPressed: provider.toggleBookmark,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildIconButton(Icons.list, "目錄", () {
                  provider.toggleControls();
                  _scaffoldKey.currentState?.openDrawer();
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
                      },
                    );
                  },
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
