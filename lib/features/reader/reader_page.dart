import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'reader_provider.dart';
import 'engine/page_view_widget.dart';
import '../../core/models/book.dart';
import '../dict/dict_dialog.dart';
import '../../shared/theme/app_theme.dart';
import '../settings/font_manager_page.dart';
import '../settings/settings_page.dart';
import '../replace_rule/replace_rule_page.dart';

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
            drawer: _buildChaptersDrawer(context, provider),
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
                  share_plus.Share.share(_selectedText);
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

  Widget _buildTopBar(BuildContext context, ReaderProvider provider) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: provider.showControls ? 0 : -100,
      left: 0,
      right: 0,
      child: AppBar(
        backgroundColor: Colors.black87,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(provider.book.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.bookmark_border, color: Colors.white), onPressed: () => provider.toggleBookmark()),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () => _showMoreMenu(context, provider)),
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

  Widget _buildBrightnessBar(BuildContext context, ReaderProvider provider) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: provider.showControls ? 120 : -100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [
            const Icon(Icons.brightness_low, color: Colors.white, size: 20),
            Expanded(child: Slider(value: provider.brightness, onChanged: provider.setBrightness)),
            const Icon(Icons.brightness_high, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ReaderProvider provider) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: provider.prevChapter),
                Expanded(child: Slider(value: provider.currentChapterIndex.toDouble(), min: 0, max: (provider.chapters.length - 1).toDouble().clamp(0, double.infinity), divisions: (provider.chapters.length - 1).clamp(1, 9999), onChanged: (v) => provider.onScrubbing(v.toInt()), onChangeEnd: (v) => provider.onScrubEnd(v.toInt()))),
                IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: provider.nextChapter),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomAction(Icons.list, "目錄", () => _scaffoldKey.currentState?.openDrawer()),
                _buildBottomAction(Icons.auto_stories, "翻頁", () => _showPageTurnModeDialog(context, provider)),
                _buildBottomAction(Icons.text_fields, "排版", () => _showTypographyDialog(context, provider)),
                _buildBottomAction(Icons.color_lens, "主題", () => _showThemeDialog(context, provider)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(children: [Icon(icon, color: Colors.white), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))]),
      ),
    );
  }

  void _showPageTurnModeDialog(BuildContext context, ReaderProvider provider) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('翻頁模式'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      _buildRadioTile("無動畫", 0, provider.pageTurnMode, provider.setPageTurnMode),
      _buildRadioTile("覆蓋 (Horizontal)", 1, provider.pageTurnMode, provider.setPageTurnMode),
      _buildRadioTile("滾動 (Vertical)", 2, provider.pageTurnMode, provider.setPageTurnMode),
      _buildRadioTile("仿真 (Simulation)", 3, provider.pageTurnMode, provider.setPageTurnMode),
    ])));
  }

  void _showTypographyDialog(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
      _buildSliderRow("字體大小", provider.fontSize, 14, 30, provider.setFontSize),
      _buildSliderRow("行高", provider.lineHeight, 1.2, 2.5, provider.setLineHeight),
      _buildSliderRow("段落間距", provider.paragraphSpacing, 0, 5, provider.setParagraphSpacing),
      _buildSliderRow("字間距", provider.letterSpacing, -1, 5, provider.setLetterSpacing),
    ]))));
  }

  void _showThemeDialog(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Container(height: 100, padding: const EdgeInsets.all(16), child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: AppTheme.readingThemes.length, itemBuilder: (context, index) {
      final theme = AppTheme.readingThemes[index];
      return GestureDetector(onTap: () => provider.setTheme(index), child: Container(width: 60, margin: const EdgeInsets.only(right: 16), decoration: BoxDecoration(color: theme.backgroundColor, shape: BoxShape.circle, border: Border.all(color: provider.themeIndex == index ? Colors.blue : Colors.grey, width: 3)), child: Center(child: Text("Aa", style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold)))));
    }))));
  }

  Widget _buildSliderRow(String label, double value, double min, double max, Function(double) onChanged) {
    return Row(children: [Text(label, style: const TextStyle(fontSize: 13)), Expanded(child: Slider(value: value, min: min, max: max, onChanged: onChanged)), Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: Colors.grey))]);
  }

  Widget _buildRadioTile(String label, int value, int groupValue, Function(int) onChanged) {
    return RadioListTile<int>(title: Text(label), value: value, groupValue: groupValue, onChanged: (v) { if (v != null) onChanged(v); Navigator.pop(context); });
  }

  Widget _buildChaptersDrawer(BuildContext context, ReaderProvider provider) {
    return Drawer(child: Column(children: [
      AppBar(title: const Text('目錄'), automaticallyImplyLeading: false),
      Expanded(child: ListView.builder(itemCount: provider.chapters.length, itemBuilder: (context, index) {
        final isCur = provider.currentChapterIndex == index;
        return ListTile(title: Text(provider.chapters[index].title, style: TextStyle(color: isCur ? Colors.blue : null, fontWeight: isCur ? FontWeight.bold : null)), onTap: () { provider.loadChapter(index); Navigator.pop(context); });
      })),
    ]));
  }
}
