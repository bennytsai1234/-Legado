import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/constant/prefer_key.dart';

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

  bool _appCrash = false;
  bool get appCrash => _appCrash;

  bool _enableReadRecord = true;
  bool get enableReadRecord => _enableReadRecord;

  String _localPassword = '';
  String get localPassword => _localPassword;

  int _lastBackup = 0;
  int get lastBackup => _lastBackup;

  int _lastVersionCode = 0;
  int get lastVersionCode => _lastVersionCode;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(PreferKey.themeMode) ?? 'system';
    _themeMode = _parseThemeMode(mode);

    _webdavUrl = prefs.getString(PreferKey.webDavUrl) ?? '';
    _webdavUser = prefs.getString(PreferKey.webDavAccount) ?? '';
    _webdavPassword = prefs.getString(PreferKey.webDavPassword) ?? '';
    _webdavEnabled = _webdavUrl.isNotEmpty && _webdavUser.isNotEmpty;

    _appCrash = prefs.getBool('app_crash') ?? false;
    _enableReadRecord = prefs.getBool('enable_read_record') ?? true;
    _localPassword = prefs.getString('local_password') ?? '';
    _lastBackup = prefs.getInt('last_backup') ?? 0;
    _lastVersionCode = prefs.getInt('last_version_code') ?? 0;

    ignoreAudioFocusAloud = prefs.getBool('ignore_audio_focus_aloud') ?? false;
    pauseReadAloudWhilePhoneCalls = prefs.getBool('pause_read_aloud_while_phone_calls') ?? false;
    readAloudWakeLock = prefs.getBool('read_aloud_wake_lock') ?? false;
    systemMediaControlCompatibilityChange = prefs.getBool('system_media_control_compatibility_change') ?? false;
    mediaButtonPerNext = prefs.getBool('media_button_per_next') ?? false;
    readAloudByPage = prefs.getBool(PreferKey.readAloudByPage) ?? false;
    streamReadAloudAudio = prefs.getBool('stream_read_aloud_audio') ?? false;

    speechRate = prefs.getDouble(PreferKey.ttsSpeechRate) ?? 0.5;
    speechPitch = prefs.getDouble('speech_pitch') ?? 1.0;
    speechVolume = prefs.getDouble('speech_volume') ?? 1.0;

    notifyListeners();
  }

  Future<void> _save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is int) await prefs.setInt(key, value);
    if (value is String) await prefs.setString(key, value);
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

  double speechRate = 0.5;
  double speechPitch = 1.0;
  double speechVolume = 1.0;

  Future<void> setAutoRefresh(bool v) async { autoRefresh = v; _save('auto_refresh', v); notifyListeners(); }
  Future<void> setDefaultToRead(bool v) async { defaultToRead = v; _save('default_to_read', v); notifyListeners(); }
  Future<void> setShowDiscovery(bool v) async { showDiscovery = v; _save('show_discovery', v); notifyListeners(); }
  Future<void> setShowRss(bool v) async { showRss = v; _save('show_rss', v); notifyListeners(); }
  Future<void> setWebServiceWakeLock(bool v) async { webServiceWakeLock = v; _save('web_service_wake_lock', v); notifyListeners(); }
  Future<void> setEnableCronet(bool v) async { enableCronet = v; _save('enable_cronet', v); notifyListeners(); }
  Future<void> setAntiAlias(bool v) async { antiAlias = v; _save('anti_alias', v); notifyListeners(); }
  Future<void> setReplaceEnableDefault(bool v) async { replaceEnableDefault = v; _save('replace_enable_default', v); notifyListeners(); }
  Future<void> setMediaButtonOnExit(bool v) async { mediaButtonOnExit = v; _save('media_button_on_exit', v); notifyListeners(); }
  Future<void> setReadAloudByMediaButton(bool v) async { readAloudByMediaButton = v; _save('read_aloud_by_media_button', v); notifyListeners(); }
  Future<void> setIgnoreAudioFocus(bool v) async { ignoreAudioFocus = v; _save('ignore_audio_focus', v); notifyListeners(); }
  Future<void> setAutoClearExpired(bool v) async { autoClearExpired = v; _save('auto_clear_expired', v); notifyListeners(); }
  Future<void> setShowAddToShelfAlert(bool v) async { showAddToShelfAlert = v; _save('show_add_to_shelf_alert', v); notifyListeners(); }
  Future<void> setShowMangaUi(bool v) async { showMangaUi = v; _save('show_manga_ui', v); notifyListeners(); }
  Future<void> setProcessText(bool v) async { processText = v; _save('process_text', v); notifyListeners(); }
  Future<void> setRecordLog(bool v) async { recordLog = v; _save('record_log', v); notifyListeners(); }
  Future<void> setRecordHeapDump(bool v) async { recordHeapDump = v; _save('record_heap_dump', v); notifyListeners(); }

  Future<void> setIgnoreAudioFocusAloud(bool v) async { ignoreAudioFocusAloud = v; _save('ignore_audio_focus_aloud', v); notifyListeners(); }
  Future<void> setPauseReadAloudWhilePhoneCalls(bool v) async { pauseReadAloudWhilePhoneCalls = v; _save('pause_read_aloud_while_phone_calls', v); notifyListeners(); }
  Future<void> setReadAloudWakeLock(bool v) async { readAloudWakeLock = v; _save('read_aloud_wake_lock', v); notifyListeners(); }
  Future<void> setSystemMediaControlCompatibilityChange(bool v) async { systemMediaControlCompatibilityChange = v; _save('system_media_control_compatibility_change', v); notifyListeners(); }
  Future<void> setMediaButtonPerNext(bool v) async { mediaButtonPerNext = v; _save('media_button_per_next', v); notifyListeners(); }
  Future<void> setReadAloudByPage(bool v) async { readAloudByPage = v; _save('read_aloud_by_page', v); notifyListeners(); }
  Future<void> setStreamReadAloudAudio(bool v) async { streamReadAloudAudio = v; _save('stream_read_aloud_audio', v); notifyListeners(); }

  Future<void> setSpeechRate(double v) async { speechRate = v; _save('speech_rate', v); notifyListeners(); }
  Future<void> setSpeechPitch(double v) async { speechPitch = v; _save('speech_pitch', v); notifyListeners(); }
  Future<void> setSpeechVolume(double v) async { speechVolume = v; _save('speech_volume', v); notifyListeners(); }

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

  Future<void> setHideStatusBar(bool v) async { hideStatusBar = v; _save('hide_status_bar', v); notifyListeners(); }
  Future<void> setHideNavigationBar(bool v) async { hideNavigationBar = v; _save('hide_navigation_bar', v); notifyListeners(); }
  Future<void> setReadBodyToLh(bool v) async { readBodyToLh = v; _save('read_body_to_lh', v); notifyListeners(); }
  Future<void> setPaddingDisplayCutouts(bool v) async { paddingDisplayCutouts = v; _save('padding_display_cutouts', v); notifyListeners(); }
  Future<void> setUseZhLayout(bool v) async { useZhLayout = v; _save('use_zh_layout', v); notifyListeners(); }
  Future<void> setTextFullJustify(bool v) async { textFullJustify = v; _save('text_full_justify', v); notifyListeners(); }
  Future<void> setTextBottomJustify(bool v) async { textBottomJustify = v; _save('text_bottom_justify', v); notifyListeners(); }
  Future<void> setMouseWheelPage(bool v) async { mouseWheelPage = v; _save('mouse_wheel_page', v); notifyListeners(); }
  Future<void> setVolumeKeyPage(bool v) async { volumeKeyPage = v; _save('volume_key_page', v); notifyListeners(); }
  Future<void> setVolumeKeyPageOnPlay(bool v) async { volumeKeyPageOnPlay = v; _save('volume_key_page_on_play', v); notifyListeners(); }
  Future<void> setKeyPageOnLongPress(bool v) async { keyPageOnLongPress = v; _save('key_page_on_long_press', v); notifyListeners(); }
  Future<void> setAutoChangeSource(bool v) async { autoChangeSource = v; _save('auto_change_source', v); notifyListeners(); }
  Future<void> setSelectText(bool v) async { selectText = v; _save('select_text', v); notifyListeners(); }
  Future<void> setShowBrightnessView(bool v) async { showBrightnessView = v; _save('show_brightness_view', v); notifyListeners(); }
  Future<void> setNoAnimScrollPage(bool v) async { noAnimScrollPage = v; _save('no_anim_scroll_page', v); notifyListeners(); }
  Future<void> setPreviewImageByClick(bool v) async { previewImageByClick = v; _save('preview_image_by_click', v); notifyListeners(); }
  Future<void> setOptimizeRender(bool v) async { optimizeRender = v; _save('optimize_render', v); notifyListeners(); }
  Future<void> setDisableReturnKey(bool v) async { disableReturnKey = v; _save('disable_return_key', v); notifyListeners(); }
  Future<void> setExpandTextMenu(bool v) async { expandTextMenu = v; _save('expand_text_menu', v); notifyListeners(); }
  Future<void> setShowReadTitleAddition(bool v) async { showReadTitleAddition = v; _save('show_read_title_addition', v); notifyListeners(); }
  Future<void> setReadBarStyleFollowPage(bool v) async { readBarStyleFollowPage = v; _save('read_bar_style_follow_page', v); notifyListeners(); }

  // Backup & WebDAV Settings Properties
  bool syncBookProgress = true;
  bool syncBookProgressPlus = false;
  bool onlyLatestBackup = true;
  bool autoCheckNewBackup = true;
  bool autoBackup = false;

  Future<void> setSyncBookProgress(bool v) async { syncBookProgress = v; _save('sync_book_progress', v); notifyListeners(); }
  Future<void> setSyncBookProgressPlus(bool v) async { syncBookProgressPlus = v; _save('sync_book_progress_plus', v); notifyListeners(); }
  Future<void> setOnlyLatestBackup(bool v) async { onlyLatestBackup = v; _save('only_latest_backup', v); notifyListeners(); }
  Future<void> setAutoCheckNewBackup(bool v) async { autoCheckNewBackup = v; _save('auto_check_new_backup', v); notifyListeners(); }
  Future<void> setAutoBackup(bool v) async { autoBackup = v; _save('auto_backup', v); notifyListeners(); }

  // Performance & Advanced Rules
  int threadCount = 8;
  String globalCoverRule = '';

  Future<void> setThreadCount(int v) async { threadCount = v; _save('thread_count', v); notifyListeners(); }
  Future<void> setGlobalCoverRule(String v) async { globalCoverRule = v; _save('global_cover_rule', v); notifyListeners(); }

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

  Future<void> setAppCrash(bool value) async {
    _appCrash = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_crash', value);
    notifyListeners();
  }

  Future<void> setEnableReadRecord(bool value) async {
    _enableReadRecord = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_read_record', value);
    notifyListeners();
  }

  Future<void> setLocalPassword(String value) async {
    _localPassword = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_password', value);
    notifyListeners();
  }

  Future<void> setLastBackup(int value) async {
    _lastBackup = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_backup', value);
    notifyListeners();
  }

  Future<void> setLastVersionCode(int value) async {
    _lastVersionCode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_version_code', value);
    notifyListeners();
  }

  /// 檢查 WebDav 備份同步 (對應 Android backupSync)
  /// 返回遠端較新的備份檔名，否則返回 null
  Future<String?> checkWebDavBackupSync() async {
    if (!_webdavEnabled || !autoCheckNewBackup) return null;
    
    try {
      debugPrint("正在檢查 WebDav 備份時間...");
      // 這裡暫時模擬發現遠端備份檔案
      const remoteTime = 1773310000000; 
      const remoteName = "backup_2026-03-12.db";
      
      if (remoteTime - _lastBackup > 60000) { // 差值大於一分鐘
        return remoteName;
      }
    } catch (e) {
      debugPrint("WebDav 同步檢查失敗: $e");
    }
    return null;
  }
}
