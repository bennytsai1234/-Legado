import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/rss_article.dart';
import 'package:legado_reader/core/database/app_database.dart';

class RssArticleDao {
  static const String tableName = 'rss_articles';

  static String createTableQuery() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        origin TEXT NOT NULL,
        sort TEXT NOT NULL,
        title TEXT NOT NULL,
        "order" INTEGER DEFAULT 0,
        link TEXT NOT NULL,
        pubDate TEXT,
        description TEXT,
        content TEXT,
        image TEXT,
        "group" TEXT DEFAULT '預設分組',
        read INTEGER DEFAULT 0,
        variable TEXT,
        PRIMARY KEY (origin, link)
      )
    ''';
  }

  Future<Database> get _db async => await AppDatabase.database;

  Future<void> insertArticles(List<RssArticle> articles) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (final a in articles) {
        await txn.insert(
          tableName,
          a.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<RssArticle>> getByOrigin(String origin) async {
    final db = await _db;
    final maps = await db.query(
      tableName,
      where: 'origin = ?',
      whereArgs: [origin],
      orderBy: '"order" ASC, pubDate DESC',
    );
    return maps.map((m) => RssArticle.fromJson(m)).toList();
  }

  Future<void> clearOrigin(String origin) async {
    final db = await _db;
    await db.delete(tableName, where: 'origin = ?', whereArgs: [origin]);
  }
  
  Future<void> updateRead(String origin, String link, bool read) async {
    final db = await _db;
    await db.update(tableName, {'read': read ? 1 : 0}, where: 'origin = ? AND link = ?', whereArgs: [origin, link]);
  }
}

