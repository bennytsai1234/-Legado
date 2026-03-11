import 'package:sqflite/sqflite.dart';
import '../../models/replace_rule.dart';
import '../app_database.dart';

/// ReplaceRuleDao - 替換規則資料存取對象
class ReplaceRuleDao {
  static const String tableName = 'replace_rules';

  Future<Database> get _db async => await AppDatabase.database;

  /// 插入或更新規則
  Future<void> insertOrUpdate(ReplaceRule rule) async {
    final db = await _db;
    await db.insert(
      tableName,
      rule.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 獲取所有規則
  Future<List<ReplaceRule>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: '"order" ASC',
    );

    return List.generate(maps.length, (i) {
      return ReplaceRule.fromJson(maps[i]);
    });
  }

  /// 獲取啟用的規則
  Future<List<ReplaceRule>> getEnabled() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'isEnabled = ?',
      whereArgs: [1],
      orderBy: '"order" ASC',
    );

    return List.generate(maps.length, (i) {
      return ReplaceRule.fromJson(maps[i]);
    });
  }

  /// 刪除規則
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// 更新啟用狀態
  Future<void> updateEnabled(int id, bool enabled) async {
    final db = await _db;
    await db.update(
      tableName,
      {'isEnabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 更新排序
  Future<void> updateOrder(int id, int order) async {
    final db = await _db;
    await db.update(
      tableName,
      {'order': order},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
