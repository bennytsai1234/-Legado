import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/database/app_database.dart';
import 'package:legado_reader/core/models/cache.dart';

/// CacheDao - 快取資料表操作
/// 對應 Android: data/dao/CacheDao.kt
class CacheDao {
  static const String tableName = 'caches';

  /// 建立表格
  static String createTableQuery() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        deadline INTEGER DEFAULT 0
      )
    ''';
  }

  Future<Cache?> get(String key) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return Cache.fromJson(maps.first);
    }
    return null;
  }

  Future<String?> getValue(String key, int now) async {
    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      columns: ['value'],
      where: 'key = ? AND (deadline = 0 OR deadline > ?)',
      whereArgs: [key, now],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> insertOrUpdate(Cache cache) async {
    final db = await AppDatabase.database;
    await db.insert(
      tableName,
      cache.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String key) async {
    final db = await AppDatabase.database;
    await db.delete(tableName, where: 'key = ?', whereArgs: [key]);
  }

  Future<void> deleteSourceVariables(String key) async {
    final db = await AppDatabase.database;
    await db.rawDelete(
      '''
        DELETE FROM $tableName 
        WHERE key LIKE 'v_' || ? || '_%'
        OR key = 'userInfo_' || ?
        OR key = 'loginHeader_' || ?
        OR key = 'sourceVariable_' || ?
      ''',
      [key, key, key, key],
    );
  }

  Future<void> clearDeadline(int now) async {
    final db = await AppDatabase.database;
    await db.delete(
      tableName,
      where: 'deadline > 0 AND deadline < ?',
      whereArgs: [now],
    );
  }
}

