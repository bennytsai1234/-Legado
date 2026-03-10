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
    final map = rule.toJson();
    _serialize(map);

    await db.insert(
      tableName,
      map,
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
      final map = Map<String, dynamic>.from(maps[i]);
      _deserialize(map);
      return ReplaceRule.fromJson(map);
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
      final map = Map<String, dynamic>.from(maps[i]);
      _deserialize(map);
      return ReplaceRule.fromJson(map);
    });
  }

  /// 刪除規則
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  void _serialize(Map<String, dynamic> map) {
    map['isEnabled'] = (map['isEnabled'] == true) ? 1 : 0;
    map['isRegex'] = (map['isRegex'] == true) ? 1 : 0;
  }

  void _deserialize(Map<String, dynamic> map) {
    map['isEnabled'] = map['isEnabled'] == 1;
    map['isRegex'] = map['isRegex'] == 1;
  }
}
