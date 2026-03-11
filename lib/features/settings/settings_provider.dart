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
