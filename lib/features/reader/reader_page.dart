import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'reader_provider.dart';
import 'engine/page_view_widget.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/features/settings/settings_page.dart';
import 'package:legado_reader/features/replace_rule/replace_rule_page.dart';
import 'widgets/reader_brightness_bar.dart';
import 'widgets/reader_chapters_drawer.dart';
import 'widgets/reader_settings_sheets.dart';
import 'widgets/reader/reader_top_menu.dart';
import 'widgets/reader/reader_bottom_menu.dart';

class ReaderPage extends StatefulWidget {
  final Book book;
  final int chapterIndex;
  final int chapterPos;
  const ReaderPage({super.key, required this.book, this.chapterIndex = 0, this.chapterPos = 0});
  @override State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late PageController _pageCtrl;
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  StreamSubscription? _jumpSub;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: widget.chapterPos + (widget.chapterIndex > 0 ? 1 : 0));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpSub = context.read<ReaderProvider>().jumpPageStream.listen((p) {
        final target = p + (context.read<ReaderProvider>().currentChapterIndex > 0 ? 1 : 0);
        if (_pageCtrl.hasClients && _pageCtrl.page?.round() != target) _pageCtrl.jumpToPage(target);
      });
    });
  }

  @override void dispose() { _jumpSub?.cancel(); _pageCtrl.dispose(); super.dispose(); }

  void _updateUI(bool show) => SystemChrome.setEnabledSystemUIMode(show ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky);

  void _handleTap(Offset pos, Size size, ReaderProvider p) {
    final x = pos.dx, y = pos.dy, w = size.width, h = size.height;
    int area = (y < h/3) ? (x < w/3 ? 0 : (x < w*2/3 ? 1 : 2)) : (y < h*2/3) ? (x < w/3 ? 3 : (x < w*2/3 ? 4 : 5)) : (x < w/3 ? 6 : (x < w*2/3 ? 7 : 8));
    _execute(p, p.clickActions[area]);
  }

  void _execute(ReaderProvider p, int action) {
    switch (action) {
      case 0: p.toggleControls(); break;
      case 1: p.nextPage(); break;
      case 2: p.currentPageIndex > 0 ? p.onPageChanged(p.currentPageIndex - 1) : p.prevChapter(); break;
      case 3: p.nextChapter(); break;
      case 4: p.prevChapter(); break;
      case 5: p.toggleTts(); break;
      case 7: p.toggleBookmark(); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) => ReaderProvider(book: widget.book, chapterIndex: widget.chapterIndex, chapterPos: widget.chapterPos), child: Scaffold(
      key: _key, body: Consumer<ReaderProvider>(builder: (context, p, _) {
        _updateUI(p.showControls);
        return Container(color: p.currentTheme.backgroundColor, child: Stack(children: [
          _buildReaderContent(p),
          if (p.pages.isNotEmpty && !p.isLoading) _buildPermanentInfo(p),
          Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.translucent, onTapUp: (d) => p.showControls ? p.toggleControls() : _handleTap(d.localPosition, context.size!, p))),
          IgnorePointer(child: Container(color: Colors.black.withValues(alpha: (1.0 - p.brightness).clamp(0.0, 0.8)))),
          ReaderTopMenu(provider: p, onMore: () => _showMore(context)),
          ReaderBrightnessBar(provider: p),
          ReaderBottomMenu(provider: p, onOpenDrawer: () => _key.currentState?.openDrawer(), onTts: p.toggleTts, onInterface: () => ReaderSettingsSheets.showInterfaceSettings(context, p), onSettings: () => ReaderSettingsSheets.showMoreSettings(context, p), onAutoPage: p.toggleAutoPage, onToggleDayNight: () => p.setTheme(p.themeIndex == 1 ? 0 : 1)),
        ]));
      }),
      drawer: Consumer<ReaderProvider>(builder: (context, p, _) => ReaderChaptersDrawer(provider: p)),
    ));
  }

  Widget _buildReaderContent(ReaderProvider p) {
    if (p.isLoading && p.pages.isEmpty) return const Center(child: CircularProgressIndicator());
    if (p.pages.isEmpty) return const Center(child: Text("暫無內容"));
    final ts = TextStyle(fontSize: p.fontSize + 4, fontWeight: FontWeight.bold, color: p.currentTheme.textColor, letterSpacing: p.letterSpacing);
    final cs = TextStyle(fontSize: p.fontSize, height: p.lineHeight, color: p.currentTheme.textColor, letterSpacing: p.letterSpacing);
    return PageView.builder(controller: _pageCtrl, itemCount: (p.currentChapterIndex > 0 ? 1 : 0) + p.pages.length + (p.currentChapterIndex < p.chapters.length - 1 ? 1 : 0), onPageChanged: (i) {
      final h = p.currentChapterIndex > 0;
      if (h && i == 0) {
        p.prevChapter();
      } else if (i == (h ? 1 : 0) + p.pages.length) p.nextChapter(); else p.onPageChanged(i - (h ? 1 : 0));
    }, itemBuilder: (ctx, i) {
      final h = p.currentChapterIndex > 0;
      if (h && i == 0) return _virtual(p, "載入中...");
      final idx = i - (h ? 1 : 0);
      return (idx == p.pages.length) ? _virtual(p, "載入中...") : PageViewWidget(page: p.pages[idx], contentStyle: cs, titleStyle: ts);
    });
  }

  Widget _buildPermanentInfo(ReaderProvider p) => Positioned(bottom: 0, left: 0, right: 0, child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Expanded(child: Text(p.book.name, style: TextStyle(color: p.currentTheme.textColor.withValues(alpha: 0.4), fontSize: 10), overflow: TextOverflow.ellipsis)),
    Text("${p.currentPageIndex + 1}/${p.pages.length}", style: TextStyle(color: p.currentTheme.textColor.withValues(alpha: 0.4), fontSize: 10)),
    SizedBox(width: 60, child: Text("${(p.chapters.isEmpty ? 0 : p.currentChapterIndex / p.chapters.length * 100).toStringAsFixed(1)}%", textAlign: TextAlign.right, style: TextStyle(color: p.currentTheme.textColor.withValues(alpha: 0.4), fontSize: 10))),
  ])));

  void _showMore(BuildContext context) => showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.rule), title: const Text('替換規則'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const ReplaceRulePage())); }), ListTile(leading: const Icon(Icons.settings), title: const Text('閱讀設定'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())); })])));
  Widget _virtual(ReaderProvider p, String t) => Container(color: p.currentTheme.backgroundColor, child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(t, style: TextStyle(color: p.currentTheme.textColor.withValues(alpha: 0.5)))])));
}
