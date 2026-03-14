import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:share_plus/share_plus.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';
import 'package:legado_reader/features/reader/engine/page_view_widget.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/features/dict/dict_dialog.dart';
import 'package:legado_reader/features/settings/font_manager_page.dart';
import 'package:legado_reader/features/settings/settings_page.dart';
import 'package:legado_reader/features/replace_rule/replace_rule_page.dart';

import 'package:legado_reader/features/reader/engine/simulation_page_view.dart';
import 'package:legado_reader/features/reader/widgets/reader_menu_top.dart';
import 'package:legado_reader/features/reader/widgets/reader_menu_bottom.dart';
import 'package:legado_reader/features/reader/widgets/reader_brightness_bar.dart';
import 'package:legado_reader/features/reader/widgets/reader_chapters_drawer.dart';
import 'package:legado_reader/features/reader/widgets/reader_settings_sheets.dart';

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
    if (_lastShowControls == show) return;
    _lastShowControls = show;
    if (show) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _executeAction(BuildContext context, ReaderProvider provider, int action) {
    switch (action) {
      case 0: // 菜單
        provider.toggleControls();
        break;
      case 1: // 下一頁
        provider.nextPage();
        break;
      case 2: // 上一頁
        provider.currentPageIndex > 0 ? provider.onPageChanged(provider.currentPageIndex - 1) : provider.prevChapter();
        break;
      case 3: // 下一章
        provider.nextChapter();
        break;
      case 4: // 上一章
        provider.prevChapter();
        break;
      case 5: // 朗讀
        provider.toggleTts();
        break;
      case 6: // 自動翻頁
        provider.toggleAutoPage();
        break;
      case 7: // 加入書籤
        provider.toggleBookmark();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('切換書籤狀態'), duration: Duration(seconds: 1)));
        break;
    }
  }

  void _handleTap(Offset position, Size size, ReaderProvider provider) {
    final double dx = position.dx;
    final double dy = position.dy;
    final double w = size.width;
    final double h = size.height;

    int area = -1;
    if (dy < h / 3) {
      if (dx < w / 3) { area = 0; }
      else if (dx < w * 2 / 3) { area = 1; }
      else { area = 2; }
    } else if (dy < h * 2 / 3) {
      if (dx < w / 3) { area = 3; }
      else if (dx < w * 2 / 3) { area = 4; }
      else { area = 5; }
    } else {
      if (dx < w / 3) { area = 6; }
      else if (dx < w * 2 / 3) { area = 7; }
      else { area = 8; }
    }

    if (area != -1) {
      final action = provider.clickActions[area];
      _executeAction(context, provider, action);
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
            drawer: ReaderChaptersDrawer(provider: provider),
            body: Stack(
              children: [
                GestureDetector(
                  onTapUp: (details) {
                    if (provider.showControls) {
                      provider.toggleControls();
                      return;
                    }
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    final offset = box.globalToLocal(details.globalPosition);
                    _handleTap(offset, box.size, provider);
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 0 && constraints.maxHeight > 0) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          provider.updateViewSize(Size(constraints.maxWidth, constraints.maxHeight));
                        });
                      }
                      return _buildContent(provider);
                    },
                  ),
                ),
                ReaderMenuTop(
                  provider: provider, 
                  onMoreMenu: () => _showMoreMenu(context, provider),
                ),
                ReaderBrightnessBar(provider: provider),
                ReaderMenuBottom(
                  provider: provider,
                  onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
                  onPageTurnMode: () => ReaderSettingsSheets.showPageTurnMode(context, provider),
                  onTypography: () => ReaderSettingsSheets.showTypography(context, provider),
                  onTheme: () => ReaderSettingsSheets.showTheme(context, provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ReaderProvider provider) {
    final theme = provider.currentTheme;
    if (provider.isLoading || provider.pages.isEmpty) {
      return Center(child: provider.isLoading ? const CircularProgressIndicator() : Text("內容為空\n${provider.content}", style: TextStyle(color: theme.textColor), textAlign: TextAlign.center));
    }
    final titleStyle = TextStyle(fontSize: provider.fontSize + 4, fontWeight: FontWeight.bold, color: theme.textColor, fontFamily: provider.fontFamily, letterSpacing: provider.letterSpacing);
    final contentStyle = TextStyle(fontSize: provider.fontSize, height: provider.lineHeight, color: theme.textColor, fontFamily: provider.fontFamily, letterSpacing: provider.letterSpacing);
    
    final Widget currentChild = PageViewWidget(page: provider.pages[provider.currentPageIndex], contentStyle: contentStyle, titleStyle: titleStyle);
    final Widget? nextChild = (provider.currentPageIndex < provider.pages.length - 1) 
        ? PageViewWidget(page: provider.pages[provider.currentPageIndex + 1], contentStyle: contentStyle, titleStyle: titleStyle) 
        : null;

    return Stack(
      children: [
        if (provider.backgroundImage.isNotEmpty && File(provider.backgroundImage).existsSync())
          Positioned.fill(
            child: Image.file(
              File(provider.backgroundImage),
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.05),
              colorBlendMode: BlendMode.darken,
            ),
          ),
        SelectionArea(
          onSelectionChanged: (c) => _selectedText = c?.plainText ?? "",
          contextMenuBuilder: (context, state) {
            final List<ContextMenuButtonItem> buttonItems = [
              ContextMenuButtonItem(
                label: '複製',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _selectedText));
                  state.hideToolbar();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已複製到剪貼簿'), duration: Duration(seconds: 1)));
                },
              ),
              if (_selectedText.isNotEmpty && num.tryParse(_selectedText) == null)
                ContextMenuButtonItem(
                  label: '查詞',
                  onPressed: () {
                    state.hideToolbar();
                    DictDialog.show(context, _selectedText);
                  },
                ),
              ContextMenuButtonItem(
                label: '筆記',
                onPressed: () {
                  state.hideToolbar();
                  _showAnnotationDialog(context, provider, _selectedText);
                },
              ),
              ContextMenuButtonItem(
                label: '搜尋',
                onPressed: () {
                  state.hideToolbar();
                  url_launcher.launchUrl(Uri.parse('https://www.google.com/search?q=$_selectedText'));
                },
              ),
              ContextMenuButtonItem(
                label: '分享',
                onPressed: () {
                  state.hideToolbar();
                  SharePlus.instance.share(_selectedText);
                },
              ),

            ];
            return AdaptiveTextSelectionToolbar.buttonItems(
              anchors: state.contextMenuAnchors,
              buttonItems: buttonItems,
            );
          },
          child: provider.pageTurnMode == 3 
            ? SimulationPageView(
                currentChild: currentChild, 
                nextChild: nextChild,
                onTurnNext: provider.nextPage,
                onTurnPrev: () => provider.currentPageIndex > 0 ? provider.onPageChanged(provider.currentPageIndex - 1) : provider.prevChapter(),
              )
            : PageView.builder(
                controller: _pageController,
                itemCount: provider.pages.length,
                onPageChanged: provider.onPageChanged,
                itemBuilder: (context, index) => PageViewWidget(page: provider.pages[index], contentStyle: contentStyle, titleStyle: titleStyle),
              ),
        ),
      ],
    );
  }

  void _showAnnotationDialog(BuildContext context, ReaderProvider provider, String text) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新增筆記'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(controller: controller, decoration: const InputDecoration(hintText: '輸入筆記內容'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('筆記已保存 (模擬)')));
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.font_download), title: const Text('字體管理'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const FontManagerPage())); }),
            ListTile(leading: const Icon(Icons.rule), title: const Text('替換規則'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ReplaceRulePage())); }),
            ListTile(leading: const Icon(Icons.settings), title: const Text('閱讀設定'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())); }),
          ],
        ),
      ),
    );
  }
}
