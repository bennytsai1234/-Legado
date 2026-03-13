import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import 'change_chapter_source_sheet.dart';
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
import 'click_action_config_page.dart';
import 'auto_read_dialog.dart';

import 'engine/simulation_page_view.dart';

class ReaderPage extends StatefulWidget {
  final Book book;
  final int chapterIndex;
  final int chapterPos;

  const ReaderPage({super.key, required this.book, this.chapterIndex = 0, this.chapterPos = 0});

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  void _updateSystemUI(bool show) {
    if (_lastShowControls == show) {
      return;
    }
    _lastShowControls = show;
    if (show) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _executeAction(BuildContext context, ReaderProvider provider, int action) {
    switch (action) {
      case 0: // 選單
        provider.toggleControls();
        break;
      case 1: // 下一頁
        if (provider.currentPageIndex < provider.pages.length - 1) {
          _pageController.animateToPage(provider.currentPageIndex + 1, duration: const Duration(milliseconds: 250), curve: Curves.easeOutQuad);
        } else {
          provider.nextChapter();
        }
        break;
      case 2: // 上一頁
        if (provider.currentPageIndex > 0) {
          _pageController.animateToPage(provider.currentPageIndex - 1, duration: const Duration(milliseconds: 250), curve: Curves.easeOutQuad);
        } else {
          provider.prevChapter();
        }
        break;
      case 3: // 下一章
        provider.nextChapter();
        break;
      case 4: // 上一章
        provider.prevChapter();
        break;
      case 7: // 加入書籤
        provider.toggleBookmark();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('切換書籤狀態'), duration: Duration(seconds: 1)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReaderProvider(book: widget.book, chapterIndex: widget.chapterIndex, chapterPos: widget.chapterPos),
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
                GestureDetector(
                  onTapUp: (details) {
                    final size = MediaQuery.of(context).size;
                    final x = details.globalPosition.dx;
                    final y = details.globalPosition.dy;
                    
                    if (provider.showControls) { provider.toggleControls(); return; }

                    // 計算九宮格索引 (0-8)
                    int col = (x / (size.width / 3)).floor().clamp(0, 2);
                    int row = (y / (size.height / 3)).floor().clamp(0, 2);
                    int index = row * 3 + col;

                    // 執行動作映射
                    int action = provider.clickActions[index];
                    _executeAction(context, provider, action);
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 0 && constraints.maxHeight > 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) { provider.updateViewSize(Size(constraints.maxWidth, constraints.maxHeight)); });
                      }
                      return _buildContent(provider, theme);
                    },
                  ),
                ),
                _buildTopBar(context, provider),
                _buildBrightnessBar(context, provider),
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
      return Center(child: provider.isLoading ? const CircularProgressIndicator() : Text("內容為空\n${provider.content}", style: TextStyle(color: theme.textColor), textAlign: TextAlign.center));
    }
    final titleStyle = TextStyle(fontSize: provider.fontSize + 4, fontWeight: FontWeight.bold, color: theme.textColor, fontFamily: provider.fontFamily);
    final contentStyle = TextStyle(fontSize: provider.fontSize, height: provider.lineHeight, color: theme.textColor, fontFamily: provider.fontFamily);
    return Stack(
      children: [
        SelectionArea(
          onSelectionChanged: (c) => _selectedText = c?.plainText ?? "",
          contextMenuBuilder: (context, state) => AdaptiveTextSelectionToolbar.buttonItems(
            anchors: state.contextMenuAnchors,
            buttonItems: [
              ...state.contextMenuButtonItems,
              if (_selectedText.isNotEmpty) ...[
                if (num.tryParse(_selectedText) == null) ContextMenuButtonItem(label: '查詞', onPressed: () { state.hideToolbar(); DictionaryService().lookup(_selectedText); }),
                ContextMenuButtonItem(label: '筆記', onPressed: () { state.hideToolbar(); _showAnnotationDialog(context, provider, _selectedText); }),
              ],
            ],
          ),
          child: provider.pageTurnMode == 3 // 仿真翻頁 (對標 Android Simulation)
            ? SimulationPageView(
                currentChild: PageViewWidget(page: provider.pages[provider.currentPageIndex], contentStyle: contentStyle, titleStyle: titleStyle),
                nextChild: provider.currentPageIndex < provider.pages.length - 1 
                    ? PageViewWidget(page: provider.pages[provider.currentPageIndex + 1], contentStyle: contentStyle, titleStyle: titleStyle)
                    : null,
                onTurnNext: () => provider.onPageChanged(provider.currentPageIndex + 1),
                onTurnPrev: () => provider.onPageChanged(provider.currentPageIndex - 1),
              )
            : PageView.builder(
                controller: _pageController,
                physics: provider.showControls ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                scrollDirection: provider.pageTurnMode == 2 ? Axis.vertical : Axis.horizontal,
                itemCount: provider.pages.length,
                onPageChanged: provider.onPageChanged,
                itemBuilder: (context, index) => PageViewWidget(page: provider.pages[index], contentStyle: contentStyle, titleStyle: titleStyle),
              ),
        ),
        if (provider.brightness < 1.0) IgnorePointer(child: Container(color: Colors.black.withValues(alpha: 1.0 - provider.brightness))),
      ]
    );
  }

  void _showAnnotationDialog(BuildContext context, ReaderProvider provider, String text) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('新增筆記'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('原文: "$text"', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        TextField(controller: ctrl, decoration: const InputDecoration(hintText: '輸入筆記內容...'), maxLines: 3, autofocus: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          await BookmarkDao().insert(Bookmark(time: DateTime.now().millisecondsSinceEpoch, bookName: provider.book.name, bookAuthor: provider.book.author, bookUrl: provider.book.bookUrl, chapterIndex: provider.currentChapterIndex, chapterPos: provider.currentPageIndex, chapterName: provider.currentChapter?.title ?? "", bookText: text, content: ctrl.text));
          if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已儲存'))); }
        }, child: const Text('儲存')),
      ],
    ));
  }

  Widget _buildTopBar(BuildContext context, ReaderProvider provider) {
    final pad = MediaQuery.of(context).padding.top;
    final h = pad + kToolbarHeight;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: provider.showControls ? 0 : -h, left: 0, right: 0,
      child: Container(
        height: h, color: Colors.black.withValues(alpha: 0.9), padding: EdgeInsets.only(top: pad),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(provider.book.name, style: const TextStyle(color: Colors.white, fontSize: 16, overflow: TextOverflow.ellipsis)),
            Text(provider.currentChapter?.title ?? "", style: const TextStyle(color: Colors.white70, fontSize: 12, overflow: TextOverflow.ellipsis)),
          ])),
          if (provider.book.origin != "local") Row(children: [
            TextButton(onPressed: () {}, style: TextButton.styleFrom(backgroundColor: Colors.white12, minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)), child: Text(provider.book.origin.length > 10 ? provider.book.origin.substring(0, 10) : provider.book.origin, style: const TextStyle(color: Colors.white, fontSize: 12))),
            PopupMenuButton<String>(icon: const Icon(Icons.more_vert, color: Colors.white), onSelected: (v) { if (v == 'auto_change_source') provider.autoChangeSource(); }, itemBuilder: (context) => [const PopupMenuItem(value: 'auto_change_source', child: Text('自動換源'))]),
          ]),
        ]),
      ),
    );
  }

  Widget _buildBrightnessBar(BuildContext context, ReaderProvider provider) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      left: provider.showControls ? 16 : -60, top: MediaQuery.of(context).size.height * 0.25, bottom: MediaQuery.of(context).size.height * 0.35,
      child: Container(
        width: 40, decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          const Padding(padding: EdgeInsets.only(top: 8), child: Icon(Icons.brightness_7, color: Colors.white, size: 20)),
          Expanded(child: RotatedBox(quarterTurns: 3, child: Slider(value: provider.brightness, min: 0.1, max: 1.0, onChanged: provider.setBrightness))),
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Icon(Icons.brightness_4, color: Colors.white, size: 20)),
        ]),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ReaderProvider provider) {
    final pad = MediaQuery.of(context).padding.bottom;
    final h = 160.0 + pad;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: provider.showControls ? 0 : -h, left: 0, right: 0,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _buildMiniFab(Icons.search, () => _showSearchDialog(context, provider)),
          _buildMiniFab(provider.isAutoPaging ? Icons.pause_circle_filled : Icons.auto_stories, () {
            if (provider.isAutoPaging) {
              provider.stopAutoPage();
            } else {
              provider.startAutoPage();
              provider.toggleControls();
              AutoReadDialog.show(context);
            }
          }),
          _buildMiniFab(Icons.find_replace, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReplaceRulePage()))),
          _buildMiniFab(provider.themeIndex == 1 ? Icons.brightness_7 : Icons.brightness_2, () => provider.setTheme(provider.themeIndex == 1 ? 0 : 1)),
        ])),
        Container(
          color: Colors.black.withValues(alpha: 0.9), padding: EdgeInsets.fromLTRB(16, 5, 16, pad + 5),
          child: Column(children: [
            Row(children: [
              TextButton(onPressed: provider.prevChapter, child: const Text("上一章", style: TextStyle(color: Colors.white, fontSize: 13))),
              Expanded(child: SliderTheme(data: SliderTheme.of(context).copyWith(valueIndicatorTextStyle: const TextStyle(color: Colors.white), showValueIndicator: ShowValueIndicator.always), child: Slider(value: provider.currentChapterIndex.toDouble(), min: 0, max: (provider.chapters.length - 1).clamp(0, 9999).toDouble(), label: provider.currentChapter?.title ?? "", onChanged: (v) => provider.onScrubbing(v.toInt()), onChangeEnd: (v) => provider.onScrubEnd(v.toInt())))),
              TextButton(onPressed: provider.nextChapter, child: const Text("下一章", style: TextStyle(color: Colors.white, fontSize: 13))),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _buildIconButton(Icons.toc, "目錄", () { provider.toggleControls(); _scaffoldKey.currentState?.openDrawer(); }),
              _buildIconButton(provider.tts.isPlaying || provider.httpTts.isPlaying ? Icons.stop : Icons.record_voice_over, "朗讀", provider.toggleTts),
              _buildIconButton(Icons.text_format, "界面", () => _showSettingsPanel(context, provider)),
              _buildIconButton(Icons.settings, "設定", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()))),
            ]),
          ]),
        ),
      ]),
    );
  }

  void _showSearchDialog(BuildContext context, ReaderProvider provider) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('正文搜尋'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '輸入搜尋關鍵字 (僅限已快取章節)'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: () { if (ctrl.text.isNotEmpty) { Navigator.pop(context); _doSearch(context, provider, ctrl.text); } }, child: const Text('搜尋')),
      ],
    ));
  }

  void _doSearch(BuildContext context, ReaderProvider provider, String kw) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    final res = await provider.searchContent(kw);
    if (!context.mounted) return;
    Navigator.pop(context);
    showModalBottomSheet(context: context, builder: (context) => Container(height: MediaQuery.of(context).size.height * 0.6, padding: const EdgeInsets.all(16), child: Column(children: [
      Text('搜尋結果: "$kw" (${res.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const Divider(),
      Expanded(child: res.isEmpty ? const Center(child: Text('未找到結果')) : ListView.builder(itemCount: res.length, itemBuilder: (context, index) {
        final item = res[index];
        return ListTile(title: Text(item['chapterTitle'] ?? ""), subtitle: Text(item['snippet'] ?? "", maxLines: 2), onTap: () { provider.loadChapter(item['chapterIndex']); Navigator.pop(context); });
      })),
    ])));
  }

  Widget _buildMiniFab(IconData icon, VoidCallback onTap) => Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))]), child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Icon(icon, color: Colors.white, size: 20))));
  Widget _buildIconButton(IconData icon, String label, VoidCallback onTap) => InkWell(onTap: onTap, child: Column(children: [Icon(icon, color: Colors.white), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 10))]));
  Widget _buildChaptersDrawer(BuildContext context, ReaderProvider provider) => _ChaptersDrawer(chapters: provider.chapters, currentChapterIndex: provider.currentChapterIndex, theme: provider.currentTheme, onChapterTap: provider.loadChapter);

  void _showSettingsPanel(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(context: context, backgroundColor: Colors.black.withValues(alpha: 0.9), builder: (context) => StatefulBuilder(builder: (context, setState) => Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("字體大小", style: TextStyle(color: Colors.white)),
      Row(children: [IconButton(onPressed: () => provider.setFontSize(provider.fontSize - 1), icon: const Icon(Icons.remove, color: Colors.white)), Text(provider.fontSize.toInt().toString(), style: const TextStyle(color: Colors.white)), IconButton(onPressed: () => provider.setFontSize(provider.fontSize + 1), icon: const Icon(Icons.add, color: Colors.white))]),
      const Text("行間距", style: TextStyle(color: Colors.white)), Slider(value: provider.lineHeight, min: 1.2, max: 2.5, onChanged: provider.setLineHeight),
      const Text("閱讀主題", style: TextStyle(color: Colors.white)), const SizedBox(height: 10),
      SizedBox(height: 40, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: AppTheme.readingThemes.length, itemBuilder: (context, index) {
        final t = AppTheme.readingThemes[index];
        return GestureDetector(onTap: () => provider.setTheme(index), child: Container(width: 60, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: t.backgroundColor, border: Border.all(color: provider.themeIndex == index ? Colors.blue : Colors.grey), borderRadius: BorderRadius.circular(4)), child: Center(child: Text("文", style: TextStyle(color: t.textColor)))));
      })),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("閱讀字體", style: TextStyle(color: Colors.white)), TextButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const FontManagerPage())); }, child: Text(provider.fontFamily ?? "系統預設", style: const TextStyle(color: Colors.blue)))]),
      const Text("翻頁方式", style: TextStyle(color: Colors.white)), Wrap(spacing: 8, children: [ChoiceChip(label: const Text('水平'), selected: provider.pageTurnMode == 0, onSelected: (v) => provider.setPageTurnMode(0)), ChoiceChip(label: const Text('覆蓋'), selected: provider.pageTurnMode == 1, onSelected: (v) => provider.setPageTurnMode(1)), ChoiceChip(label: const Text('垂直'), selected: provider.pageTurnMode == 2, onSelected: (v) => provider.setPageTurnMode(2))]),
      const SizedBox(height: 10),
      const Text("亮度調節", style: TextStyle(color: Colors.white)), Slider(value: provider.brightness, min: 0.1, max: 1.0, onChanged: provider.setBrightness),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("繁簡轉換", style: TextStyle(color: Colors.white)), Switch(value: provider.chineseConvert, onChanged: provider.setChineseConvert)]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("反轉內容", style: TextStyle(color: Colors.white)), Switch(value: provider.reverseContent, onChanged: (v) { provider.toggleReverseContent(); setState(() {}); })]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("刪除重複標題", style: TextStyle(color: Colors.white)), Switch(value: provider.removeSameTitle, onChanged: (v) { provider.toggleRemoveSameTitle(); setState(() {}); })]),
      const Divider(color: Colors.white24),
      ListTile(
        title: const Text("單章換源", style: TextStyle(color: Colors.white)),
        subtitle: const Text("為當前章節搜尋其他來源", style: TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.swap_horiz, color: Colors.white54),
        onTap: () {
          Navigator.pop(context);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => ChangeChapterSourceSheet(
              book: provider.book,
              chapterIndex: provider.currentChapterIndex,
              chapterTitle: provider.currentChapter?.title ?? "未知章節",
            ),
          );
        },
      ),
      ListTile(
        title: const Text("點擊區域自定義", style: TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChangeNotifierProvider.value(value: provider, child: const ClickActionConfigPage())));
        },
      ),
    ]))));
  }
}

class _ChaptersDrawer extends StatefulWidget {
  final List<BookChapter> chapters;
  final int currentChapterIndex;
  final ReadingTheme theme;
  final Function(int) onChapterTap;
  const _ChaptersDrawer({required this.chapters, required this.currentChapterIndex, required this.theme, required this.onChapterTap});
  @override State<_ChaptersDrawer> createState() => _ChaptersDrawerState();
}

class _ChaptersDrawerState extends State<_ChaptersDrawer> {
  late TextEditingController _ctrl;
  List<int> _filtered = [];
  late ScrollController _scroll;
  @override void initState() { super.initState(); _ctrl = TextEditingController(); _filtered = List.generate(widget.chapters.length, (i) => i); _scroll = ScrollController(initialScrollOffset: (widget.currentChapterIndex * 50.0).clamp(0, double.infinity)); }
  @override void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }
  void _filter(String q) => setState(() => _filtered = q.isEmpty ? List.generate(widget.chapters.length, (i) => i) : widget.chapters.asMap().entries.where((e) => e.value.title.toLowerCase().contains(q.toLowerCase())).map((e) => e.key).toList());
  @override Widget build(BuildContext context) {
    return Drawer(backgroundColor: widget.theme.backgroundColor, child: Column(children: [
      Container(padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16, bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("目錄", style: TextStyle(color: widget.theme.textColor, fontSize: 18, fontWeight: FontWeight.bold)), Text("${widget.chapters.length} 章", style: TextStyle(color: widget.theme.textColor.withValues(alpha: 0.7), fontSize: 12))]),
        const SizedBox(height: 10),
        TextField(controller: _ctrl, style: TextStyle(color: widget.theme.textColor), decoration: InputDecoration(hintText: "搜尋章節...", hintStyle: TextStyle(color: widget.theme.textColor.withValues(alpha: 0.5)), prefixIcon: Icon(Icons.search, color: widget.theme.textColor.withValues(alpha: 0.5)), filled: true, fillColor: widget.theme.textColor.withValues(alpha: 0.1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: EdgeInsets.zero), onChanged: _filter),
      ])),
      const Divider(height: 1),
      Expanded(child: ListView.builder(controller: _scroll, padding: EdgeInsets.zero, itemCount: _filtered.length, itemBuilder: (context, index) {
        final realIdx = _filtered[index];
        final isCur = widget.currentChapterIndex == realIdx;
        return ListTile(dense: true, title: Text(widget.chapters[realIdx].title, style: TextStyle(color: isCur ? Colors.blue : widget.theme.textColor, fontWeight: isCur ? FontWeight.bold : FontWeight.normal)), onTap: () { widget.onChapterTap(realIdx); Navigator.pop(context); });
      })),
    ]));
  }
}
