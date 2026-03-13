import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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
import 'features/about/about_page.dart';
import 'features/book_detail/change_cover_provider.dart';
import 'features/association/intent_handler_service.dart';
import 'core/services/tts_service.dart';
import 'core/services/webdav_service.dart';
import 'core/services/crash_handler.dart';
import 'core/engine/app_event_bus.dart';
import 'core/services/default_data.dart';

// 背景任務回呼函數 (對應 Android DownloadService)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("正在執行背景下載任務: $task");
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化崩潰日誌
  await CrashHandler.init();

  // 初始化背景任務
  Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

  // 全域錯誤捕獲 (對應 Android CrashHandler)
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint("Flutter Error: ${details.exception}");
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('app_crash', true));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("Platform Error: $error");
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('app_crash', true));
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
        ChangeNotifierProvider(create: (_) => ChangeCoverProvider()),
        ChangeNotifierProvider(create: (_) => TTSService()),
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
          locale: settings.locale,
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
    final settings = context.watch<SettingsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final customPath = isDarkMode ? settings.welcomeImageDark : settings.welcomeImage;
    final showIcon = isDarkMode ? settings.welcomeShowIconDark : settings.welcomeShowIcon;
    final showText = isDarkMode ? settings.welcomeShowTextDark : settings.welcomeShowText;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          customPath.isNotEmpty && File(customPath).existsSync()
              ? Image.file(File(customPath), fit: BoxFit.cover)
              : Image.asset(
                  'assets/welcome_bg.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: const Center(
                      child: Icon(Icons.library_books, size: 100, color: Colors.blue),
                    ),
                  ),
                ),
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
                      if (showIcon) ...[
                        const Icon(Icons.library_books, color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                      ],
                      if (showText) ...[
                        const Text(
                          'Legado Reader',
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '「 讀萬卷書，行萬里路 」',
                          style: TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                        ),
                      ],
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
  int _newChapterCount = 0;
  DateTime _lastTapTime = DateTime.now();
  DateTime? _lastBackTime;

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

    final now = DateTime.now();
    if (_lastBackTime == null || now.difference(_lastBackTime!) > const Duration(seconds: 2)) {
      _lastBackTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('再按一次退出'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    final isTtsPlaying = context.read<TTSService>().isPlaying;
    if (isTtsPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('朗讀正在運行，已為您保持背景播放')),
      );
      return true;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      IntentHandlerService().init(context);
      _checkAppCrash();
      _checkLocalPassword();
      _checkBackupSync();
      _checkVersionUpdate();
    });
    _autoRefreshBookshelf();
  }

  Future<void> _checkVersionUpdate() async {
    final settings = context.read<SettingsProvider>();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = int.tryParse(packageInfo.buildNumber) ?? 0;
    
    if (currentVersion != settings.lastVersionCode && mounted) {
      final isFirst = settings.lastVersionCode == 0;
      settings.setLastVersionCode(currentVersion);
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isFirst ? '歡迎使用' : '更新日誌'),
          content: SingleChildScrollView(
            child: Text(isFirst 
              ? '感謝您使用 Legado Reader iOS 移植版！\n\n這是一個開源的閱讀器，旨在還原 Android 端 Legado 的強大功能。' 
              : '版本更新至 v${packageInfo.version} (${packageInfo.buildNumber})\n\n[深度補齊計畫]\n- 實作了 WebDav 自動比對還原\n- 實作了啟動版本引導與日誌\n- 補齊了多項原始碼級別邏輯'),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('確定'))],
        ),
      );
    }
  }

  void _checkLocalPassword() {
    final settings = context.read<SettingsProvider>();
    if (settings.localPassword.isEmpty) {
      final ctrl = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('設定本地密碼'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('為了保護您的備份安全，建議設定一個本地密碼。', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(hintText: '輸入密碼', isDense: true, border: OutlineInputBorder()),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () { settings.setLocalPassword(""); Navigator.pop(ctx); }, child: const Text('不設定')),
            ElevatedButton(onPressed: () { settings.setLocalPassword(ctrl.text.trim()); Navigator.pop(ctx); }, child: const Text('確定')),
          ],
        ),
      );
    }
  }

  void _checkAppCrash() {
    final settings = context.read<SettingsProvider>();
    if (settings.appCrash) {
      settings.setAppCrash(false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('崩潰提醒'),
          content: const Text('偵測到上次運行時發生了崩潰，是否打開崩潰日誌以便查看問題？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AppLogPage()));
              },
              child: const Text('查看日誌'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _checkBackupSync() async {
    final settings = context.read<SettingsProvider>();
    final remoteBackupName = await settings.checkWebDavBackupSync();
    
    if (remoteBackupName != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('發現新備份'),
          content: Text('在 WebDav 上發現了更晚的備份檔案：\n$remoteBackupName\n\n是否立即還原資料？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在從 WebDav 還原資料...')));
                final success = await WebDAVService().restoreFromFile('/legado/$remoteBackupName');
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('還原成功！正在重啟書架...')));
                  context.read<BookshelfProvider>().refreshBookshelf();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('還原失敗，請檢查網路'), backgroundColor: Colors.red));
                }
              },
              child: const Text('立即還原'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _autoRefreshBookshelf() async {
    try {
      final provider = context.read<BookshelfProvider>();
      await provider.refreshBookshelf();
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
    IntentHandlerService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      TTSService().stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final List<Map<String, dynamic>> menuItems = [
          {'icon': Icons.book_outlined, 'selectedIcon': Icons.book, 'label': '書架', 'page': const BookshelfPage()},
        ];

        if (settings.showDiscovery) {
          menuItems.add({'icon': Icons.explore_outlined, 'selectedIcon': Icons.explore, 'label': '發現', 'page': const ExplorePage()});
        }

        menuItems.add({'icon': Icons.source_outlined, 'selectedIcon': Icons.source, 'label': '書源', 'page': const SourceManagerPage()});

        if (settings.showRss) {
          menuItems.add({
            'icon': Consumer<RssSourceProvider>(builder: (ctx, rss, child) => Badge(isLabelVisible: rss.unreadCount > 0, label: Text('${rss.unreadCount}'), child: const Icon(Icons.rss_feed_outlined))),
            'selectedIcon': const Icon(Icons.rss_feed),
            'label': '訂閱',
            'page': const RssSourcePage()
          });
        }

        menuItems.add({'icon': Icons.settings_outlined, 'selectedIcon': Icons.settings, 'label': '設定', 'page': const SettingsPage()});

        // 確保索引不越界
        if (_currentIndex >= menuItems.length) {
          _currentIndex = menuItems.length - 1;
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, dynamic result) async {
            if (didPop) return;
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) {
              await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            }
          },
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: menuItems.map((item) => item['page'] as Widget).toList(),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                if (_currentIndex == index) {
                  final now = DateTime.now();
                  if (now.difference(_lastTapTime).inMilliseconds < 300) {
                    final label = menuItems[index]['label'];
                    if (label == '書架') {
                      AppEventBus().fire(AppEventBus.upBookshelf);
                    } else if (label == '發現') {
                      AppEventBus().fire("explore_event");
                    }
                  }
                  _lastTapTime = now;
                  return;
                }

                setState(() {
                  _currentIndex = index;
                  if (menuItems[index]['label'] == '書架') _newChapterCount = 0;
                  if (menuItems[index]['label'] == '訂閱') context.read<RssSourceProvider>().clearUnread();
                });
              },
              destinations: menuItems.map((item) {
                if (item['label'] == '書架') {
                  return NavigationDestination(
                    icon: Consumer<BookshelfProvider>(
                      builder: (ctx, bookshelf, child) {
                        final upCount = bookshelf.updatingCount;
                        final label = upCount > 0 ? '$upCount' : (_newChapterCount > 0 ? '$_newChapterCount' : '');
                        final isUpdate = upCount > 0;
                        return Badge(
                          isLabelVisible: isUpdate || _newChapterCount > 0,
                          label: Text(label),
                          backgroundColor: isUpdate ? Colors.blue : Colors.red,
                          child: Icon(item['icon'] as IconData),
                        );
                      },
                    ),
                    selectedIcon: Consumer<BookshelfProvider>(
                      builder: (ctx, bookshelf, child) {
                        final upCount = bookshelf.updatingCount;
                        final label = upCount > 0 ? '$upCount' : (_newChapterCount > 0 ? '$_newChapterCount' : '');
                        final isUpdate = upCount > 0;
                        return Badge(
                          isLabelVisible: isUpdate || _newChapterCount > 0,
                          label: Text(label),
                          backgroundColor: isUpdate ? Colors.blue : Colors.red,
                          child: Icon(item['selectedIcon'] as IconData),
                        );
                      },
                    ),
                    label: item['label'] as String,
                  );
                }
                return NavigationDestination(
                  icon: item['icon'] is Widget ? item['icon'] as Widget : Icon(item['icon'] as IconData),
                  selectedIcon: item['selectedIcon'] is Widget ? item['selectedIcon'] as Widget : Icon(item['selectedIcon'] as IconData),
                  label: item['label'] as String,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
