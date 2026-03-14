import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/database/app_database.dart';

/// SearchHistoryDao - 搜尋歷史資料存取對象
class SearchHistoryDao {
  static const String tableName = 'search_history';

  Future<Database> get _db async => await AppDatabase.database;

  /// 添加歷史記錄（如果已存在則更新時間）
  Future<void> add(String keyword) async {
    final db = await _db;
    await db.insert(tableName, {
      'keyword': keyword,
      'searchTime': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 獲取最近的歷史記錄
  Future<List<String>> getRecent({int limit = 20}) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'searchTime DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => maps[i]['keyword'] as String);
  }

  /// 刪除單個記錄
  Future<void> delete(String keyword) async {
    final db = await _db;
    await db.delete(tableName, where: 'keyword = ?', whereArgs: [keyword]);
  }

  /// 清空所有歷史
  Future<void> clearAll() async {
    final db = await _db;
    await db.delete(tableName);
  }
}

