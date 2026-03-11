import 'package:sqflite/sqflite.dart';
import '../../models/rule_sub.dart';
import '../app_database.dart';

class RuleSubDao {
  static const String tableName = 'rule_subs';

  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        type INTEGER DEFAULT 0,
        customOrder INTEGER DEFAULT 0,
        autoUpdate INTEGER DEFAULT 0,
        "update" INTEGER DEFAULT 0
      )
    ''';
  }

  Future<Database> get _db async => await AppDatabase.database;

  Future<void> insertOrUpdate(RuleSub sub) async {
    final db = await _db;
    final map = sub.toJson();
    map['autoUpdate'] = (map['autoUpdate'] == true) ? 1 : 0;
    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RuleSub>> getAll() async {
    final db = await _db;
    final maps = await db.query(tableName, orderBy: 'customOrder ASC');
    return maps.map((m) {
      final map = Map<String, dynamic>.from(m);
      map['autoUpdate'] = map['autoUpdate'] == 1;
      return RuleSub.fromJson(map);
    }).toList();
  }
}
