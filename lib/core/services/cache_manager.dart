import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// CacheManager - 檔案快取管理器
/// 參考 Android: help/CacheManager.kt
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  /// 獲取快取檔案路徑
  Future<String> getCachePath(String key) async {
    final cacheDir = await getTemporaryDirectory();
    return p.join(cacheDir.path, "js_cache", key);
  }

  /// 讀取快取文本
  Future<String?> get(String key) async {
    final path = await getCachePath(key);
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  /// 保存快取文本
  Future<void> put(String key, String content) async {
    final path = await getCachePath(key);
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(content);
  }

  /// 刪除快取
  Future<void> delete(String key) async {
    final path = await getCachePath(key);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
