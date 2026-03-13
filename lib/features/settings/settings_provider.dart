import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../../core/constant/prefer_key.dart';
import '../../core/services/webdav_service.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Locale? _locale;
  Locale? get locale => _locale;

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

  // 封面進階設定 (深度還原 Android)
  int _coverSearchPriority = 0; // 0: 書源優先, 1: 規則優先
  int _coverTimeout = 5000; // ms
  String _globalCoverRule = '';

  int get coverSearchPriority => _coverSearchPriority;
  int get coverTimeout => _coverTimeout;
  String get globalCoverRule => _globalCoverRule;

  // --- 主題色彩設定 ---
  bool transparentStatusBar = true;
  bool immNavigationBar = true;
  Color dayPrimaryColor = Colors.brown;
  Color dayAccentColor = Colors.red;
  Color dayBackgroundColor = Colors.grey.shade100;
  Color dayBottomBackgroundColor = Colors.grey.shade200;
  Color nightPrimaryColor = Colors.blueGrey.shade600;
  Color nightAccentColor = Colors.deepOrange.shade800;
  Color nightBackgroundColor = Colors.grey.shade900;
  Color nightBottomBackgroundColor = Colors.grey.shade800;

  // --- 閱讀設定 ---
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

  // --- 備份設定 ---
  bool syncBookProgress = true;
  bool syncBookProgressPlus = false;
  bool onlyLatestBackup = true;
  bool autoCheckNewBackup = true;
  bool autoBackup = false;

  // --- 其他設定 ---
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
  int threadCount = 8;
  String userAgent = '';
  String bookStorageDir = '';

  // --- 朗讀設定 ---
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

  // --- 歡迎介面設定 ---
  String welcomeImage = '';
  String welcomeImageDark = '';
  bool welcomeShowText = true;
  bool welcomeShowIcon = true;
  bool welcomeShowTextDark = true;
  bool welcomeShowIconDark = true;

  // --- 啟動圖標設定 ---
  String launcherIcon = '';

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(PreferKey.themeMode) ?? 'system';
    _themeMode = _parseThemeMode(mode);

    final lang = prefs.getString(PreferKey.language) ?? 'system';
    _locale = _parseLocale(lang);

    welcomeImage = prefs.getString(PreferKey.welcomeImage) ?? '';
    welcomeImageDark = prefs.getString(PreferKey.welcomeImageDark) ?? '';
    welcomeShowText = prefs.getBool(PreferKey.welcomeShowText) ?? true;
    welcomeShowIcon = prefs.getBool(PreferKey.welcomeShowIcon) ?? true;
    welcomeShowTextDark = prefs.getBool('welcome_show_text_dark') ?? true;
    welcomeShowIconDark = prefs.getBool('welcome_show_icon_dark') ?? true;
    launcherIcon = prefs.getString(PreferKey.launcherIcon) ?? '';

    _webdavUrl = prefs.getString(PreferKey.webDavUrl) ?? '';
    _webdavUser = prefs.getString(PreferKey.webDavAccount) ?? '';
    _webdavPassword = prefs.getString(PreferKey.webDavPassword) ?? '';
    _webdavEnabled = _webdavUrl.isNotEmpty && _webdavUser.isNotEmpty;

    _appCrash = prefs.getBool('app_crash') ?? false;
    _enableReadRecord = prefs.getBool('enable_read_record') ?? true;
    _localPassword = prefs.getString('local_password') ?? '';
    _lastBackup = prefs.getInt('last_backup') ?? 0;
    _lastVersionCode = prefs.getInt('last_version_code') ?? 0;

    _coverSearchPriority = prefs.getInt('cover_search_priority') ?? 0;
    _coverTimeout = prefs.getInt('cover_timeout') ?? 5000;
    _globalCoverRule = prefs.getString('global_cover_rule') ?? '';

    transparentStatusBar = prefs.getBool('transparent_status_bar') ?? true;
    immNavigationBar = prefs.getBool('imm_navigation_bar') ?? true;
    hideStatusBar = prefs.getBool('hide_status_bar') ?? false;
    hideNavigationBar = prefs.getBool('hide_navigation_bar') ?? false;
    readBodyToLh = prefs.getBool('read_body_to_lh') ?? true;
    paddingDisplayCutouts = prefs.getBool('padding_display_cutouts') ?? false;
    useZhLayout = prefs.getBool('use_zh_layout') ?? false;
    textFullJustify = prefs.getBool('text_full_justify') ?? true;
    textBottomJustify = prefs.getBool('text_bottom_justify') ?? true;
    mouseWheelPage = prefs.getBool('mouse_wheel_page') ?? true;
    volumeKeyPage = prefs.getBool('volume_key_page') ?? true;
    volumeKeyPageOnPlay = prefs.getBool('volume_key_page_on_play') ?? false;
    keyPageOnLongPress = prefs.getBool('key_page_on_long_press') ?? false;
    autoChangeSource = prefs.getBool('auto_change_source') ?? true;
    selectText = prefs.getBool('select_text') ?? true;
    showBrightnessView = prefs.getBool('show_brightness_view') ?? true;
    noAnimScrollPage = prefs.getBool('no_anim_scroll_page') ?? false;
    previewImageByClick = prefs.getBool('preview_image_by_click') ?? false;
    optimizeRender = prefs.getBool('optimize_render') ?? false;
    disableReturnKey = prefs.getBool('disable_return_key') ?? false;
    expandTextMenu = prefs.getBool('expand_text_menu') ?? false;
    showReadTitleAddition = prefs.getBool('show_read_title_addition') ?? true;
    readBarStyleFollowPage = prefs.getBool('read_bar_style_follow_page') ?? false;

    syncBookProgress = prefs.getBool('sync_book_progress') ?? true;
    syncBookProgressPlus = prefs.getBool('sync_book_progress_plus') ?? false;
    onlyLatestBackup = prefs.getBool('only_latest_backup') ?? true;
    autoCheckNewBackup = prefs.getBool('auto_check_new_backup') ?? true;
    autoBackup = prefs.getBool('auto_backup') ?? false;

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

    autoRefresh = prefs.getBool('auto_refresh') ?? false;
    defaultToRead = prefs.getBool('default_to_read') ?? false;
    showDiscovery = prefs.getBool('show_discovery') ?? true;
    showRss = prefs.getBool('show_rss') ?? true;
    webServiceWakeLock = prefs.getBool('web_service_wake_lock') ?? false;
    enableCronet = prefs.getBool('enable_cronet') ?? false;
    antiAlias = prefs.getBool('anti_alias') ?? false;
    replaceEnableDefault = prefs.getBool('replace_enable_default') ?? true;
    mediaButtonOnExit = prefs.getBool('media_button_on_exit') ?? true;
    readAloudByMediaButton = prefs.getBool('read_aloud_by_media_button') ?? false;
    ignoreAudioFocus = prefs.getBool('ignore_audio_focus') ?? false;
    autoClearExpired = prefs.getBool('auto_clear_expired') ?? true;
    showAddToShelfAlert = prefs.getBool('show_add_to_shelf_alert') ?? true;
    showMangaUi = prefs.getBool('show_manga_ui') ?? true;
    processText = prefs.getBool('process_text') ?? true;
    recordLog = prefs.getBool('record_log') ?? false;
    recordHeapDump = prefs.getBool('record_heap_dump') ?? false;
    threadCount = prefs.getInt('thread_count') ?? 8;
    userAgent = prefs.getString(PreferKey.userAgent) ?? '';
    bookStorageDir = prefs.getString('book_storage_dir') ?? '';

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
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  Locale? _parseLocale(String lang) {
    if (lang == 'system') return null;
    final parts = lang.split('_');
    if (parts.length == 2) return Locale(parts[0], parts[1]);
    return Locale(lang);
  }

  Future<void> setLanguage(String lang) async {
    _locale = _parseLocale(lang);
    await _save(PreferKey.language, lang);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _save(PreferKey.themeMode, mode.toString().split('.').last);
    notifyListeners();
  }

  // --- Setter Methods ---
  Future<void> setCoverSearchPriority(int val) async { _coverSearchPriority = val; await _save('cover_search_priority', val); notifyListeners(); }
  Future<void> setCoverTimeout(int val) async { _coverTimeout = val; await _save('cover_timeout', val); notifyListeners(); }
  Future<void> setGlobalCoverRule(String val) async { _globalCoverRule = val; await _save('global_cover_rule', val); notifyListeners(); }

  Future<void> updateWebDav({required String url, required String user, required String password}) async {
    _webdavUrl = url; _webdavUser = user; _webdavPassword = password;
    _webdavEnabled = url.isNotEmpty && user.isNotEmpty && password.isNotEmpty;
    await _save(PreferKey.webDavUrl, url);
    await _save(PreferKey.webDavAccount, user);
    await _save(PreferKey.webDavPassword, password);
    await _save('webdav_enabled', _webdavEnabled);
    notifyListeners();
  }

  Future<void> setTransparentStatusBar(bool v) async { transparentStatusBar = v; await _save('transparent_status_bar', v); notifyListeners(); }
  Future<void> setImmNavigationBar(bool v) async { immNavigationBar = v; await _save('imm_navigation_bar', v); notifyListeners(); }
  Future<void> setHideStatusBar(bool v) async { hideStatusBar = v; await _save('hide_status_bar', v); notifyListeners(); }
  Future<void> setHideNavigationBar(bool v) async { hideNavigationBar = v; await _save('hide_navigation_bar', v); notifyListeners(); }
  Future<void> setReadBodyToLh(bool v) async { readBodyToLh = v; await _save('read_body_to_lh', v); notifyListeners(); }
  Future<void> setPaddingDisplayCutouts(bool v) async { paddingDisplayCutouts = v; await _save('padding_display_cutouts', v); notifyListeners(); }
  Future<void> setUseZhLayout(bool v) async { useZhLayout = v; await _save('use_zh_layout', v); notifyListeners(); }
  Future<void> setTextFullJustify(bool v) async { textFullJustify = v; await _save('text_full_justify', v); notifyListeners(); }
  Future<void> setTextBottomJustify(bool v) async { textBottomJustify = v; await _save('text_bottom_justify', v); notifyListeners(); }
  Future<void> setMouseWheelPage(bool v) async { mouseWheelPage = v; await _save('mouse_wheel_page', v); notifyListeners(); }
  Future<void> setVolumeKeyPage(bool v) async { volumeKeyPage = v; await _save('volume_key_page', v); notifyListeners(); }
  Future<void> setVolumeKeyPageOnPlay(bool v) async { volumeKeyPageOnPlay = v; await _save('volume_key_page_on_play', v); notifyListeners(); }
  Future<void> setKeyPageOnLongPress(bool v) async { keyPageOnLongPress = v; await _save('key_page_on_long_press', v); notifyListeners(); }
  Future<void> setAutoChangeSource(bool v) async { autoChangeSource = v; await _save('auto_change_source', v); notifyListeners(); }
  Future<void> setSelectText(bool v) async { selectText = v; await _save('select_text', v); notifyListeners(); }
  Future<void> setShowBrightnessView(bool v) async { showBrightnessView = v; await _save('show_brightness_view', v); notifyListeners(); }
  Future<void> setNoAnimScrollPage(bool v) async { noAnimScrollPage = v; await _save('no_anim_scroll_page', v); notifyListeners(); }
  Future<void> setPreviewImageByClick(bool v) async { previewImageByClick = v; await _save('preview_image_by_click', v); notifyListeners(); }
  Future<void> setOptimizeRender(bool v) async { optimizeRender = v; await _save('optimize_render', v); notifyListeners(); }
  Future<void> setDisableReturnKey(bool v) async { disableReturnKey = v; await _save('disable_return_key', v); notifyListeners(); }
  Future<void> setExpandTextMenu(bool v) async { expandTextMenu = v; await _save('expand_text_menu', v); notifyListeners(); }
  Future<void> setShowReadTitleAddition(bool v) async { showReadTitleAddition = v; await _save('show_read_title_addition', v); notifyListeners(); }
  Future<void> setReadBarStyleFollowPage(bool v) async { readBarStyleFollowPage = v; await _save('read_bar_style_follow_page', v); notifyListeners(); }

  Future<void> setSyncBookProgress(bool v) async { syncBookProgress = v; await _save('sync_book_progress', v); notifyListeners(); }
  Future<void> setSyncBookProgressPlus(bool v) async { syncBookProgressPlus = v; await _save('sync_book_progress_plus', v); notifyListeners(); }
  Future<void> setOnlyLatestBackup(bool v) async { onlyLatestBackup = v; await _save('only_latest_backup', v); notifyListeners(); }
  Future<void> setAutoCheckNewBackup(bool v) async { autoCheckNewBackup = v; await _save('auto_check_new_backup', v); notifyListeners(); }
  Future<void> setAutoBackup(bool v) async { autoBackup = v; await _save('auto_backup', v); notifyListeners(); }

  Future<void> setAutoRefresh(bool v) async { autoRefresh = v; await _save('auto_refresh', v); notifyListeners(); }
  Future<void> setDefaultToRead(bool v) async { defaultToRead = v; await _save('default_to_read', v); notifyListeners(); }
  Future<void> setShowDiscovery(bool v) async { showDiscovery = v; await _save('show_discovery', v); notifyListeners(); }
  Future<void> setShowRss(bool v) async { showRss = v; await _save('show_rss', v); notifyListeners(); }
  Future<void> setWebServiceWakeLock(bool v) async { webServiceWakeLock = v; await _save('web_service_wake_lock', v); notifyListeners(); }
  Future<void> setEnableCronet(bool v) async { enableCronet = v; await _save('enable_cronet', v); notifyListeners(); }
  Future<void> setAntiAlias(bool v) async { antiAlias = v; await _save('anti_alias', v); notifyListeners(); }
  Future<void> setReplaceEnableDefault(bool v) async { replaceEnableDefault = v; await _save('replace_enable_default', v); notifyListeners(); }
  Future<void> setMediaButtonOnExit(bool v) async { mediaButtonOnExit = v; await _save('media_button_on_exit', v); notifyListeners(); }
  Future<void> setReadAloudByMediaButton(bool v) async { readAloudByMediaButton = v; await _save('read_aloud_by_media_button', v); notifyListeners(); }
  Future<void> setIgnoreAudioFocus(bool v) async { ignoreAudioFocus = v; await _save('ignore_audio_focus', v); notifyListeners(); }
  Future<void> setAutoClearExpired(bool v) async { autoClearExpired = v; await _save('auto_clear_expired', v); notifyListeners(); }
  Future<void> setShowAddToShelfAlert(bool v) async { showAddToShelfAlert = v; await _save('show_add_to_shelf_alert', v); notifyListeners(); }
  Future<void> setShowMangaUi(bool v) async { showMangaUi = v; await _save('show_manga_ui', v); notifyListeners(); }
  Future<void> setProcessText(bool v) async { processText = v; await _save('process_text', v); notifyListeners(); }
  Future<void> setRecordLog(bool v) async { recordLog = v; await _save('record_log', v); notifyListeners(); }
  Future<void> setRecordHeapDump(bool v) async { recordHeapDump = v; await _save('record_heap_dump', v); notifyListeners(); }
  Future<void> setThreadCount(int v) async { threadCount = v; await _save('thread_count', v); notifyListeners(); }
  Future<void> setUserAgent(String v) async { userAgent = v; await _save(PreferKey.userAgent, v); notifyListeners(); }
  Future<void> setBookStorageDir(String v) async { bookStorageDir = v; await _save('book_storage_dir', v); notifyListeners(); }

  Future<void> setDayPrimaryColor(Color c) async { dayPrimaryColor = c; notifyListeners(); }
  Future<void> setDayAccentColor(Color c) async { dayAccentColor = c; notifyListeners(); }
  Future<void> setDayBackgroundColor(Color c) async { dayBackgroundColor = c; notifyListeners(); }
  Future<void> setDayBottomBackgroundColor(Color c) async { dayBottomBackgroundColor = c; notifyListeners(); }
  Future<void> setNightPrimaryColor(Color c) async { nightPrimaryColor = c; notifyListeners(); }
  Future<void> setNightAccentColor(Color c) async { nightAccentColor = c; notifyListeners(); }
  Future<void> setNightBackgroundColor(Color c) async { nightBackgroundColor = c; notifyListeners(); }
  Future<void> setNightBottomBackgroundColor(Color c) async { nightBottomBackgroundColor = c; notifyListeners(); }

  Future<void> setIgnoreAudioFocusAloud(bool v) async { ignoreAudioFocusAloud = v; await _save('ignore_audio_focus_aloud', v); notifyListeners(); }
  Future<void> setPauseReadAloudWhilePhoneCalls(bool v) async { pauseReadAloudWhilePhoneCalls = v; await _save('pause_read_aloud_while_phone_calls', v); notifyListeners(); }
  Future<void> setReadAloudWakeLock(bool v) async { readAloudWakeLock = v; await _save('read_aloud_wake_lock', v); notifyListeners(); }
  Future<void> setSystemMediaControlCompatibilityChange(bool v) async { systemMediaControlCompatibilityChange = v; await _save('system_media_control_compatibility_change', v); notifyListeners(); }
  Future<void> setMediaButtonPerNext(bool v) async { mediaButtonPerNext = v; await _save('media_button_per_next', v); notifyListeners(); }
  Future<void> setReadAloudByPage(bool v) async { readAloudByPage = v; await _save(PreferKey.readAloudByPage, v); notifyListeners(); }
  Future<void> setStreamReadAloudAudio(bool v) async { streamReadAloudAudio = v; await _save('stream_read_aloud_audio', v); notifyListeners(); }
  Future<void> setSpeechRate(double v) async { speechRate = v; await _save(PreferKey.ttsSpeechRate, v); notifyListeners(); }
  Future<void> setSpeechPitch(double v) async { speechPitch = v; await _save('speech_pitch', v); notifyListeners(); }
  Future<void> setSpeechVolume(double v) async { speechVolume = v; await _save('speech_volume', v); notifyListeners(); }

  // --- 歡迎介面 Setter ---
  Future<void> setWelcomeImage(String v) async { welcomeImage = v; await _save(PreferKey.welcomeImage, v); notifyListeners(); }
  Future<void> setWelcomeImageDark(String v) async { welcomeImageDark = v; await _save(PreferKey.welcomeImageDark, v); notifyListeners(); }
  Future<void> setWelcomeShowText(bool v) async { welcomeShowText = v; await _save(PreferKey.welcomeShowText, v); notifyListeners(); }
  Future<void> setWelcomeShowIcon(bool v) async { welcomeShowIcon = v; await _save(PreferKey.welcomeShowIcon, v); notifyListeners(); }
  Future<void> setWelcomeShowTextDark(bool v) async { welcomeShowTextDark = v; await _save('welcome_show_text_dark', v); notifyListeners(); }
  Future<void> setWelcomeShowIconDark(bool v) async { welcomeShowIconDark = v; await _save('welcome_show_icon_dark', v); notifyListeners(); }

  // --- 啟動圖標 Setter ---
  Future<void> setLauncherIcon(String v) async {
    launcherIcon = v;
    await _save(PreferKey.launcherIcon, v);
    
    // 調用原生 Android 邏輯
    if (Platform.isAndroid) {
      try {
        const platform = MethodChannel('com.legado.reader/launcher_icon');
        await platform.invokeMethod('changeIcon', {'iconName': v});
      } catch (e) {
        debugPrint('變更啟動圖標失敗: $e');
      }
    }
    
    notifyListeners();
  }

  /// 資料庫操作
  Future<String?> backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'legado_reader.db');
      final dbFile = File(path);
      if (!await dbFile.exists()) return null;
      final backupDir = await getApplicationDocumentsDirectory();
      final backupPath = join(backupDir.path, 'legado_backup_${DateTime.now().millisecondsSinceEpoch}.db');
      await dbFile.copy(backupPath);
      return backupPath;
    } catch (e) { debugPrint('備份失敗: $e'); return null; }
  }

  Future<bool> restoreDatabase(String backupPath) async {
    try {
      await AppDatabase.close();
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'legado_reader.db');
      await File(backupPath).copy(path);
      return true;
    } catch (e) { debugPrint('還原失敗: $e'); return false; }
  }

  Future<void> clearCache() async {
    final db = await AppDatabase.database;
    await db.delete('chapter_contents');
    notifyListeners();
  }

  Future<void> setEnableReadRecord(bool value) async { _enableReadRecord = value; await _save('enable_read_record', value); notifyListeners(); }
  Future<void> setLastBackup(int value) async { _lastBackup = value; await _save('last_backup', value); notifyListeners(); }
  Future<void> setLastVersionCode(int value) async { _lastVersionCode = value; await _save('last_version_code', value); notifyListeners(); }
  Future<void> setLocalPassword(String value) async { _localPassword = value; await _save('local_password', value); notifyListeners(); }
  Future<void> setAppCrash(bool value) async { _appCrash = value; await _save('app_crash', value); notifyListeners(); }

  Future<String?> checkWebDavBackupSync() async {
    if (!_webdavEnabled || !autoCheckNewBackup) return null;
    try {
      final lastFile = await WebDAVService().lastBackUp();
      if (lastFile == null) return null;
      
      // 解析備份檔案名稱中的時間戳 (格式: backup_12345678.zip)
      final name = lastFile.name ?? "";
      final tsStr = name.replaceAll('backup_', '').replaceAll('.zip', '');
      final remoteTs = int.tryParse(tsStr) ?? 0;
      
      if (remoteTs > _lastBackup) {
        return name;
      }
    } catch (e) {
      debugPrint('Check WebDav sync failed: $e');
    }
    return null;
  }
}
