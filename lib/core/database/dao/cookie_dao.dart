import 'package:sqflite/sqflite.dart';
import '../../models/cookie.dart';
import '../app_database.dart';

/// CookieDao - Cookie 資料存取對象
class CookieDao {
  static const String tableName = 'cookies';

  Future<Database> get _db async => await AppDatabase.database;

  /// 插入或更新 Cookie
  Future<void> insertOrUpdate(Cookie cookie) async {
    final db = await _db;
    await db.insert(
      tableName,
      cookie.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 根據 URL (通常是域名) 獲取 Cookie
  Future<Cookie?> getByUrl(String url) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'url = ?',
      whereArgs: [url],
    );

    if (maps.isEmpty) return null;
    return Cookie.fromJson(maps.first);
  }

  /// 刪除指定 URL 的 Cookie
  Future<void> delete(String url) async {
    final db = await _db;
    await db.delete(tableName, where: 'url = ?', whereArgs: [url]);
  }

  /// 清空所有 Cookie
  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete(tableName);
  }
}
