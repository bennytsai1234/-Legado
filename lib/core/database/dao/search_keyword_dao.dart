import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/search_keyword.dart';
import 'package:legado_reader/core/database/app_database.dart';

class SearchKeywordDao {
  static const String tableName = 'search_keywords';

  static String createTableQuery() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        word TEXT PRIMARY KEY,
        usage INTEGER DEFAULT 0,
        lastUseTime INTEGER DEFAULT 0,
        isAction INTEGER DEFAULT 0
      )
    ''';
  }

  Future<Database> get _db async => await AppDatabase.database;

  Future<void> addKeyword(String word) async {
    final db = await _db;
    await db.execute('''
      INSERT INTO $tableName (word, usage, lastUseTime)
      VALUES (?, 1, ?)
      ON CONFLICT(word) DO UPDATE SET 
        usage = usage + 1,
        lastUseTime = excluded.lastUseTime
    ''', [word, DateTime.now().millisecondsSinceEpoch]);
  }

  Future<List<SearchKeyword>> getTopKeywords({int limit = 20}) async {
    final db = await _db;
    final maps = await db.query(
      tableName,
      orderBy: 'usage DESC, lastUseTime DESC',
      limit: limit,
    );
    return maps.map((m) => SearchKeyword.fromJson(m)).toList();
  }
}

