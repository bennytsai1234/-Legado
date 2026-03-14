import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/keyboard_assist.dart';
import 'package:legado_reader/core/database/app_database.dart';

class KeyboardAssistDao {
  static const String tableName = 'keyboard_assists';

  static String createTableQuery() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        serialNo INTEGER DEFAULT 0
      )
    ''';
  }

  Future<Database> get _db async => await AppDatabase.database;

  Future<void> insert(KeyboardAssist assist) async {
    final db = await _db;
    await db.insert(
      tableName,
      assist.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

