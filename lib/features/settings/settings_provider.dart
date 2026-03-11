import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // WebDAV
  String _webdavUrl = '';
  String _webdavUser = '';
  String _webdavPassword = '';
  bool _webdavEnabled = false;

  String get webdavUrl => _webdavUrl;
  String get webdavUser => _webdavUser;
  String get webdavPassword => _webdavPassword;
  bool get webdavEnabled => _webdavEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode') ?? 'system';
    _themeMode = _parseThemeMode(mode);

    _webdavUrl = prefs.getString('webdav_url') ?? '';
    _webdavUser = prefs.getString('webdav_user') ?? '';
    _webdavPassword = prefs.getString('webdav_password') ?? '';
    _webdavEnabled = prefs.getBool('webdav_enabled') ?? false;

    notifyListeners();
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString().split('.').last);
    notifyListeners();
  }

  Future<void> updateWebDav({
    required String url,
    required String user,
    required String password,
  }) async {
    _webdavUrl = url;
    _webdavUser = user;
    _webdavPassword = password;
    _webdavEnabled = url.isNotEmpty && user.isNotEmpty && password.isNotEmpty;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('webdav_url', url);
    await prefs.setString('webdav_user', user);
    await prefs.setString('webdav_password', password);
    await prefs.setBool('webdav_enabled', _webdavEnabled);
    notifyListeners();
  }

  // Theme Config Properties
  bool _transparentStatusBar = true;
  bool _immNavigationBar = true;
  Color _dayPrimaryColor = Colors.brown;
  Color _dayAccentColor = Colors.red;
  Color _dayBackgroundColor = Colors.grey.shade100;
  Color _dayBottomBackgroundColor = Colors.grey.shade200;
  Color _nightPrimaryColor = Colors.blueGrey.shade600;
  Color _nightAccentColor = Colors.deepOrange.shade800;
  Color _nightBackgroundColor = Colors.grey.shade900;
  Color _nightBottomBackgroundColor = Colors.grey.shade800;

  bool get transparentStatusBar => _transparentStatusBar;
  bool get immNavigationBar => _immNavigationBar;
  Color get dayPrimaryColor => _dayPrimaryColor;
  Color get dayAccentColor => _dayAccentColor;
  Color get dayBackgroundColor => _dayBackgroundColor;
  Color get dayBottomBackgroundColor => _dayBottomBackgroundColor;
  Color get nightPrimaryColor => _nightPrimaryColor;
  Color get nightAccentColor => _nightAccentColor;
  Color get nightBackgroundColor => _nightBackgroundColor;
  Color get nightBottomBackgroundColor => _nightBottomBackgroundColor;

  Future<void> setTransparentStatusBar(bool value) async {
    _transparentStatusBar = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('transparent_status_bar', value);
    notifyListeners();
  }

  Future<void> setImmNavigationBar(bool value) async {
    _immNavigationBar = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('imm_navigation_bar', value);
    notifyListeners();
  }

  Future<void> setDayPrimaryColor(Color color) async { _dayPrimaryColor = color; notifyListeners(); }
  Future<void> setDayAccentColor(Color color) async { _dayAccentColor = color; notifyListeners(); }
  Future<void> setDayBackgroundColor(Color color) async { _dayBackgroundColor = color; notifyListeners(); }
  Future<void> setDayBottomBackgroundColor(Color color) async { _dayBottomBackgroundColor = color; notifyListeners(); }
  Future<void> setNightPrimaryColor(Color color) async { _nightPrimaryColor = color; notifyListeners(); }
  Future<void> setNightAccentColor(Color color) async { _nightAccentColor = color; notifyListeners(); }
  Future<void> setNightBackgroundColor(Color color) async { _nightBackgroundColor = color; notifyListeners(); }
  Future<void> setNightBottomBackgroundColor(Color color) async { _nightBottomBackgroundColor = color; notifyListeners(); }

  // Other Settings Properties
  bool autoRefresh = false;
  bool defaultToRead = false;
  bool showDiscovery = true;
  bool showRss = true;
  bool webServiceWakeLock = false;
  bool enableCronet = false;
  bool antiAlias = false;
  bool replaceEnableDefault = true;
  bool mediaButtonOnExit = true;
  bool readAloudByMediaButton = false;
  bool ignoreAudioFocus = false;
  bool autoClearExpired = true;
  bool showAddToShelfAlert = true;
  bool showMangaUi = true;
  bool processText = true;
  bool recordLog = false;
  bool recordHeapDump = false;

  // Aloud Settings Properties
  bool ignoreAudioFocusAloud = false;
  bool pauseReadAloudWhilePhoneCalls = false;
  bool readAloudWakeLock = false;
  bool systemMediaControlCompatibilityChange = false;
  bool mediaButtonPerNext = false;
  bool readAloudByPage = false;
  bool streamReadAloudAudio = false;

  Future<void> setAutoRefresh(bool v) async { autoRefresh = v; notifyListeners(); }
  Future<void> setDefaultToRead(bool v) async { defaultToRead = v; notifyListeners(); }
  Future<void> setShowDiscovery(bool v) async { showDiscovery = v; notifyListeners(); }
  Future<void> setShowRss(bool v) async { showRss = v; notifyListeners(); }
  Future<void> setWebServiceWakeLock(bool v) async { webServiceWakeLock = v; notifyListeners(); }
  Future<void> setEnableCronet(bool v) async { enableCronet = v; notifyListeners(); }
  Future<void> setAntiAlias(bool v) async { antiAlias = v; notifyListeners(); }
  Future<void> setReplaceEnableDefault(bool v) async { replaceEnableDefault = v; notifyListeners(); }
  Future<void> setMediaButtonOnExit(bool v) async { mediaButtonOnExit = v; notifyListeners(); }
  Future<void> setReadAloudByMediaButton(bool v) async { readAloudByMediaButton = v; notifyListeners(); }
  Future<void> setIgnoreAudioFocus(bool v) async { ignoreAudioFocus = v; notifyListeners(); }
  Future<void> setAutoClearExpired(bool v) async { autoClearExpired = v; notifyListeners(); }
  Future<void> setShowAddToShelfAlert(bool v) async { showAddToShelfAlert = v; notifyListeners(); }
  Future<void> setShowMangaUi(bool v) async { showMangaUi = v; notifyListeners(); }
  Future<void> setProcessText(bool v) async { processText = v; notifyListeners(); }
  Future<void> setRecordLog(bool v) async { recordLog = v; notifyListeners(); }
  Future<void> setRecordHeapDump(bool v) async { recordHeapDump = v; notifyListeners(); }

  Future<void> setIgnoreAudioFocusAloud(bool v) async { ignoreAudioFocusAloud = v; notifyListeners(); }
  Future<void> setPauseReadAloudWhilePhoneCalls(bool v) async { pauseReadAloudWhilePhoneCalls = v; notifyListeners(); }
  Future<void> setReadAloudWakeLock(bool v) async { readAloudWakeLock = v; notifyListeners(); }
  Future<void> setSystemMediaControlCompatibilityChange(bool v) async { systemMediaControlCompatibilityChange = v; notifyListeners(); }
  Future<void> setMediaButtonPerNext(bool v) async { mediaButtonPerNext = v; notifyListeners(); }
  Future<void> setReadAloudByPage(bool v) async { readAloudByPage = v; notifyListeners(); }
  Future<void> setStreamReadAloudAudio(bool v) async { streamReadAloudAudio = v; notifyListeners(); }

  // Reading Settings Properties
  bool hideStatusBar = false;
  bool hideNavigationBar = false;
  bool readBodyToLh = true;
  bool paddingDisplayCutouts = false;
  bool useZhLayout = false;
  bool textFullJustify = true;
  bool textBottomJustify = true;
  bool mouseWheelPage = true;
  bool volumeKeyPage = true;
  bool volumeKeyPageOnPlay = false;
  bool keyPageOnLongPress = false;
  bool autoChangeSource = true;
  bool selectText = true;
  bool showBrightnessView = true;
  bool noAnimScrollPage = false;
  bool previewImageByClick = false;
  bool optimizeRender = false;
  bool disableReturnKey = false;
  bool expandTextMenu = false;
  bool showReadTitleAddition = true;
  bool readBarStyleFollowPage = false;

  Future<void> setHideStatusBar(bool v) async { hideStatusBar = v; notifyListeners(); }
  Future<void> setHideNavigationBar(bool v) async { hideNavigationBar = v; notifyListeners(); }
  Future<void> setReadBodyToLh(bool v) async { readBodyToLh = v; notifyListeners(); }
  Future<void> setPaddingDisplayCutouts(bool v) async { paddingDisplayCutouts = v; notifyListeners(); }
  Future<void> setUseZhLayout(bool v) async { useZhLayout = v; notifyListeners(); }
  Future<void> setTextFullJustify(bool v) async { textFullJustify = v; notifyListeners(); }
  Future<void> setTextBottomJustify(bool v) async { textBottomJustify = v; notifyListeners(); }
  Future<void> setMouseWheelPage(bool v) async { mouseWheelPage = v; notifyListeners(); }
  Future<void> setVolumeKeyPage(bool v) async { volumeKeyPage = v; notifyListeners(); }
  Future<void> setVolumeKeyPageOnPlay(bool v) async { volumeKeyPageOnPlay = v; notifyListeners(); }
  Future<void> setKeyPageOnLongPress(bool v) async { keyPageOnLongPress = v; notifyListeners(); }
  Future<void> setAutoChangeSource(bool v) async { autoChangeSource = v; notifyListeners(); }
  Future<void> setSelectText(bool v) async { selectText = v; notifyListeners(); }
  Future<void> setShowBrightnessView(bool v) async { showBrightnessView = v; notifyListeners(); }
  Future<void> setNoAnimScrollPage(bool v) async { noAnimScrollPage = v; notifyListeners(); }
  Future<void> setPreviewImageByClick(bool v) async { previewImageByClick = v; notifyListeners(); }
  Future<void> setOptimizeRender(bool v) async { optimizeRender = v; notifyListeners(); }
  Future<void> setDisableReturnKey(bool v) async { disableReturnKey = v; notifyListeners(); }
  Future<void> setExpandTextMenu(bool v) async { expandTextMenu = v; notifyListeners(); }
  Future<void> setShowReadTitleAddition(bool v) async { showReadTitleAddition = v; notifyListeners(); }
  Future<void> setReadBarStyleFollowPage(bool v) async { readBarStyleFollowPage = v; notifyListeners(); }

  // Backup & WebDAV Settings Properties
  bool syncBookProgress = true;
  bool syncBookProgressPlus = false;
  bool onlyLatestBackup = true;
  bool autoCheckNewBackup = true;

  Future<void> setSyncBookProgress(bool v) async { syncBookProgress = v; notifyListeners(); }
  Future<void> setSyncBookProgressPlus(bool v) async { syncBookProgressPlus = v; notifyListeners(); }
  Future<void> setOnlyLatestBackup(bool v) async { onlyLatestBackup = v; notifyListeners(); }
  Future<void> setAutoCheckNewBackup(bool v) async { autoCheckNewBackup = v; notifyListeners(); }

  /// 資料庫備份
  Future<String?> backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'legado_reader.db');
      final dbFile = File(path);

      if (!await dbFile.exists()) return null;

      Directory? backupDir;
      if (Platform.isAndroid) {
        backupDir = Directory('/storage/emulated/0/Download');
      } else {
        backupDir = await getApplicationDocumentsDirectory();
      }

      if (!await backupDir.exists()) {
        backupDir = await getTemporaryDirectory();
      }

      final backupPath = join(
        backupDir.path,
        'legado_reader_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      await dbFile.copy(backupPath);
      return backupPath;
    } catch (e) {
      debugPrint('備份失敗: $e');
      return null;
    }
  }

  /// 資料庫還原
  Future<bool> restoreDatabase(String backupPath) async {
    try {
      // 關閉當前資料庫
      await AppDatabase.close();

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'legado_reader.db');

      final backupFile = File(backupPath);
      await backupFile.copy(path);

      // 重新開啟資料庫 (會由下一個 get database 觸發)
      return true;
    } catch (e) {
      debugPrint('還原失敗: $e');
      return false;
    }
  }

  /// 清除快取
  Future<void> clearCache() async {
    final db = await AppDatabase.database;
    await db.delete('chapter_contents');
    notifyListeners();
  }
}
