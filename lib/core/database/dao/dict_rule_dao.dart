import 'package:sqflite/sqflite.dart';
import '../../models/dict_rule.dart';
import '../app_database.dart';

class DictRuleDao {
  static const String tableName = 'dict_rules';

  static String createTableQuery() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        name TEXT PRIMARY KEY,
        urlRule TEXT NOT NULL,
        showRule TEXT,
        sortNumber INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 1
      )
    ''';
  }

  Future<Database> get _db async => await AppDatabase.database;

  Future<void> insertOrUpdate(DictRule rule) async {
    final db = await _db;
    await db.insert(
      tableName,
      rule.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertOrUpdateAll(List<DictRule> rules) async {
    final db = await _db;
    final batch = db.batch();
    for (final rule in rules) {
      batch.insert(
        tableName,
        rule.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<DictRule>> getAll() async {
    final db = await _db;
    final maps = await db.query(tableName, orderBy: 'sortNumber ASC');
    return maps.map((m) => DictRule.fromJson(m)).toList();
  }

  Future<void> delete(String name) async {
    final db = await _db;
    await db.delete(
      tableName,
      where: 'name = ?',
      whereArgs: [name],
    );
  }
}

