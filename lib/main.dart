import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'shared/theme/app_theme.dart';
import 'features/bookshelf/bookshelf_provider.dart';
import 'features/explore/explore_provider.dart';
import 'features/source_manager/source_manager_provider.dart';
import 'features/search/search_provider.dart';
import 'features/settings/settings_provider.dart';
import 'features/settings/font_provider.dart';
import 'features/dict/dict_provider.dart';
import 'features/rss/rss_source_provider.dart';
import 'features/book_detail/change_cover_provider.dart';
import 'core/services/tts_service.dart';
import 'core/services/crash_handler.dart';
import 'features/welcome/splash_page.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    return Future.value(true);
  });
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CrashHandler.init();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('app_crash', true));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
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
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(create: (_) => ChangeCoverProvider()),
        ChangeNotifierProvider(create: (_) => DictProvider()),
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
          scaffoldMessengerKey: scaffoldMessengerKey,
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
