import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/core/constant/prefer_key.dart';
import 'provider/settings_base.dart';
import 'provider/settings_ui_theme.dart';
import 'provider/settings_reading.dart';
import 'provider/settings_sync_backup.dart';
import 'provider/settings_advanced.dart';

export 'provider/settings_base.dart';
export 'provider/settings_ui_theme.dart';
export 'provider/settings_reading.dart';
export 'provider/settings_sync_backup.dart';
export 'provider/settings_advanced.dart';

/// SettingsProvider - 設置提供者 (重構後)
/// 對應 Android: help/config/AppConfig.kt
class SettingsProvider extends SettingsProviderBase {
  // WebDAV
  String webdavUrl = '';
  String webdavUser = '';
  String webdavPassword = '';
  String webdavSubDir = '';
  String deviceName = '';
  bool webdavEnabled = false;

  bool appCrash = false;
  bool enableReadRecord = true;
  String localPassword = '';
  int lastBackup = 0;
  int lastVersionCode = 0;
  bool privacyAgreed = false;

  // 封面進階設定
  int coverSearchPriority = 0;
  int coverTimeout = 5000;
  String globalCoverRule = '';

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
  String dayBackgroundImage = '';
  String nightBackgroundImage = '';

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

  // --- 歡迎介面與圖標 ---
  String welcomeImage = '';
  String welcomeImageDark = '';
  bool welcomeShowText = true;
  bool welcomeShowIcon = true;
  String launcherIcon = '';

  // 其他
  bool recordLog = false;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(PreferKey.themeMode) ?? 'system';
    themeMode = parseThemeMode(mode);

    final lang = prefs.getString(PreferKey.language) ?? 'system';
    locale = parseLocale(lang);

    welcomeImage = prefs.getString(PreferKey.welcomeImage) ?? '';
    welcomeShowText = prefs.getBool(PreferKey.welcomeShowText) ?? true;
    launcherIcon = prefs.getString(PreferKey.launcherIcon) ?? '';
    dayBackgroundImage = prefs.getString(PreferKey.bgImage) ?? '';
    nightBackgroundImage = prefs.getString(PreferKey.bgImageN) ?? '';

    webdavUrl = prefs.getString(PreferKey.webDavUrl) ?? '';
    webdavUser = prefs.getString(PreferKey.webDavAccount) ?? '';
    webdavPassword = prefs.getString(PreferKey.webDavPassword) ?? '';
    webdavEnabled = webdavUrl.isNotEmpty && webdavUser.isNotEmpty;

    lastBackup = prefs.getInt('last_backup') ?? 0;
    coverSearchPriority = prefs.getInt('cover_search_priority') ?? 0;
    coverTimeout = prefs.getInt('cover_timeout') ?? 5000;
    globalCoverRule = prefs.getString('global_cover_rule') ?? '';

    hideStatusBar = prefs.getBool('hide_status_bar') ?? false;
    hideNavigationBar = prefs.getBool('hide_navigation_bar') ?? false;
    volumeKeyPage = prefs.getBool('volume_key_page') ?? true;
    autoChangeSource = prefs.getBool('auto_change_source') ?? true;
    optimizeRender = prefs.getBool('optimize_render') ?? false;

    speechRate = prefs.getDouble(PreferKey.ttsSpeechRate) ?? 0.5;
    speechPitch = prefs.getDouble('speech_pitch') ?? 1.0;
    speechVolume = prefs.getDouble('speech_volume') ?? 1.0;

    privacyAgreed = prefs.getBool('privacy_agreed') ?? false;
    recordLog = prefs.getBool('record_log') ?? false;

    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    locale = parseLocale(lang);
    await save(PreferKey.language, lang);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await save(PreferKey.themeMode, mode.toString().split('.').last);
    notifyListeners();
  }
}
