import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'shared/theme/app_theme.dart';
import 'features/bookshelf/bookshelf_page.dart';
import 'features/explore/explore_page.dart';
import 'features/bookshelf/bookshelf_provider.dart';
import 'features/explore/explore_provider.dart';
import 'features/source_manager/source_manager_page.dart';
import 'features/source_manager/source_manager_provider.dart';
import 'features/search/search_provider.dart';
import 'features/settings/settings_page.dart';
import 'features/settings/settings_provider.dart';
import 'features/rss/rss_source_page.dart';
import 'features/rss/rss_source_provider.dart';
import 'core/services/default_data.dart';
import 'core/services/tts_service.dart';
import 'package:flutter/foundation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 全域錯誤捕獲 (對應 Android CrashHandler)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("Flutter Error: ${details.exception}");
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("Platform Error: $error");
    return true;
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SourceManagerProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => BookshelfProvider()),
        ChangeNotifierProvider(create: (_) => ExploreProvider()),
        ChangeNotifierProvider(create: (_) => RssSourceProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const LegadoReaderApp(),
    ),
  );
}

class LegadoReaderApp extends StatelessWidget {
  const LegadoReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Legado Reader',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          home: const SplashPage(),
        );
      },
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _status = '正在初始化...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      setState(() => _status = '正在載入資料庫與預設資料...');
      await DefaultData.init();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      }
    } catch (e, stack) {
      debugPrint("Init Error: $e\n$stack");
      if (mounted) {
        setState(() {
          _error = "$e\n$stack";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 背景圖 (對應 Android WelcomeActivity)
          Image.asset(
            'assets/welcome_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Center(
                child: Icon(Icons.library_books, size: 100, color: Colors.blue),
              ),
            ),
          ),
          // 漸層遮罩
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: _error != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('啟動失敗: $_error', style: const TextStyle(color: Colors.redAccent)),
                  )
                : Column(
                    children: [
                      const Text(
                        'Legado Reader',
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '「 讀萬卷書，行萬里路 」',
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 40),
                      Text(_status, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.white10),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _newChapterCount = 0; // 未讀新章節更新數量 (對應 Android onUpBooksLiveData)

  final List<Widget> _pages = const [
    BookshelfPage(),
    ExplorePage(),
    SourceManagerPage(),
    RssSourcePage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 對應 Android MainViewModel.upAllBookToc() —— 啟動時靜默更新書架
    _autoRefreshBookshelf();
  }

  /// 啟動後自動靜默更新書架所有書籍的目錄
  Future<void> _autoRefreshBookshelf() async {
    try {
      final provider = context.read<BookshelfProvider>();
      await provider.refreshBookshelf();
      // 統計有多少書新增了章節
      int count = 0;
      for (final book in provider.books) {
        if (book.lastCheckCount > 0) count += book.lastCheckCount;
      }
      if (mounted && count > 0) {
        setState(() => _newChapterCount = count);
      }
    } catch (e) {
      debugPrint('自動更新書架失敗: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // App 進入背景或退出，停止 TTS (對應 Android LifecycleHelp)
      TTSService().stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            // 切到書架時清除 badge
            if (index == 0) _newChapterCount = 0;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _newChapterCount > 0,
              label: Text('$_newChapterCount'),
              child: const Icon(Icons.book_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _newChapterCount > 0,
              label: Text('$_newChapterCount'),
              child: const Icon(Icons.book),
            ),
            label: '書架',
          ),
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: '發現',
          ),
          const NavigationDestination(
            icon: Icon(Icons.source_outlined),
            selectedIcon: Icon(Icons.source),
            label: '書源',
          ),
          const NavigationDestination(
            icon: Icon(Icons.rss_feed_outlined),
            selectedIcon: Icon(Icons.rss_feed),
            label: '訂閱',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
