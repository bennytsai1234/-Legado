import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/rss_star.dart';
import 'package:legado_reader/core/database/app_database.dart';

class RssStarDao {
  static const String tableName = 'rss_stars';

  static String createTableQuery() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        origin TEXT NOT NULL,
        link TEXT NOT NULL,
        title TEXT NOT NULL,
        pubDate TEXT,
        description TEXT,
        image TEXT,
        starTime INTEGER DEFAULT 0,
        PRIMARY KEY (origin, link)
      )
    ''';
  }

  Future<Database> get _db async => await AppDatabase.database;

  Future<void> insert(RssStar star) async {
    final db = await _db;
    await db.insert(
      tableName,
      star.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String origin, String link) async {
    final db = await _db;
    await db.delete(
      tableName,
      where: 'origin = ? AND link = ?',
      whereArgs: [origin, link],
    );
  }

  Future<List<RssStar>> getAll() async {
    final db = await _db;
    final maps = await db.query(tableName, orderBy: 'starTime DESC');
    return maps.map((m) => RssStar.fromJson(m)).toList();
  }
}

