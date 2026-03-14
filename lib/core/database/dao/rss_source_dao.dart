import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/rss_source.dart';
import 'package:legado_reader/core/database/app_database.dart';

class RssSourceDao {
  static const String tableName = 'rss_sources';

  static String createTableQuery() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        sourceUrl TEXT PRIMARY KEY,
        sourceName TEXT NOT NULL,
        sourceIcon TEXT,
        sourceGroup TEXT,
        sourceComment TEXT,
        enabled INTEGER DEFAULT 1,
        variableComment TEXT,
        jsLib TEXT,
        enabledCookieJar INTEGER DEFAULT 1,
        concurrentRate TEXT,
        header TEXT,
        loginUrl TEXT,
        loginUi TEXT,
        loginCheckJs TEXT,
        coverDecodeJs TEXT,
        sortUrl TEXT,
        singleUrl INTEGER DEFAULT 0,
        articleStyle INTEGER DEFAULT 0,
        ruleArticles TEXT,
        ruleNextPage TEXT,
        ruleTitle TEXT,
        rulePubDate TEXT,
        ruleDescription TEXT,
        ruleImage TEXT,
        ruleLink TEXT,
        ruleContent TEXT,
        contentWhitelist TEXT,
        contentBlacklist TEXT,
        shouldOverrideUrlLoading TEXT,
        style TEXT,
        enableJs INTEGER DEFAULT 1,
        loadWithBaseUrl INTEGER DEFAULT 1,
        injectJs TEXT,
        lastUpdateTime INTEGER DEFAULT 0,
        customOrder INTEGER DEFAULT 0
      )
    ''';
  }

  Future<Database> get _db async => await AppDatabase.database;

  Future<void> insertOrUpdate(RssSource source) async {
    final db = await _db;
    await db.insert(
      tableName,
      source.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertOrUpdateAll(List<RssSource> sources) async {
    final db = await _db;
    final batch = db.batch();
    for (final source in sources) {
      batch.insert(
        tableName,
        source.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<RssSource>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(tableName, orderBy: 'customOrder ASC, lastUpdateTime DESC');
    return maps.map((m) => RssSource.fromJson(m)).toList();
  }

  Future<List<RssSource>> getEnabled() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(tableName, where: 'enabled = ?', whereArgs: [1], orderBy: 'customOrder ASC');
    return maps.map((m) => RssSource.fromJson(m)).toList();
  }
  
  Future<void> updateEnabled(String url, bool enabled) async {
    final db = await _db;
    await db.update(tableName, {'enabled': enabled ? 1 : 0}, where: 'sourceUrl = ?', whereArgs: [url]);
  }

  Future<void> delete(String url) async {
    final db = await _db;
    await db.delete(tableName, where: 'sourceUrl = ?', whereArgs: [url]);
  }

  Future<List<String>> getGroups() async {
    final db = await _db;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT DISTINCT sourceGroup FROM $tableName WHERE sourceGroup IS NOT NULL AND sourceGroup != ""',
    );
    final groups = <String>{};
    for (final row in result) {
      final groupStr = row['sourceGroup'] as String;
      groups.addAll(groupStr.split(RegExp(r'[,;，；]')).map((e) => e.trim()));
    }
    return groups.toList()..sort();
  }
}

