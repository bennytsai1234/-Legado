import 'package:sqflite/sqflite.dart';
import '../../models/txt_toc_rule.dart';
import '../app_database.dart';

class TxtTocRuleDao {
  static const String tableName = 'txt_toc_rules';

  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rule TEXT NOT NULL,
        example TEXT,
        serialNumber INTEGER DEFAULT -1,
        enable INTEGER DEFAULT 1
      )
    ''';
  }

  Future<Database> get _db async => await AppDatabase.database;

  Future<void> insertOrUpdate(TxtTocRule rule) async {
    final db = await _db;
    await db.insert(
      tableName,
      rule.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TxtTocRule>> getEnabled() async {
    final db = await _db;
    final maps = await db.query(
      tableName,
      where: 'enable = 1',
      orderBy: 'serialNumber ASC',
    );
    return maps.map((m) => TxtTocRule.fromJson(m)).toList();
  }
}
