import 'package:sqflite/sqflite.dart';
import '../../models/http_tts.dart';
import '../app_database.dart';

class HttpTtsDao {
  static const String tableName = 'http_tts';

  static String createTableQuery() {
    return '''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        contentType TEXT,
        concurrentRate TEXT,
        loginUrl TEXT,
        loginUi TEXT,
        header TEXT,
        jsLib TEXT,
        enabledCookieJar INTEGER DEFAULT 0,
        loginCheckJs TEXT,
        lastUpdateTime INTEGER DEFAULT 0
      )
    ''';
  }

  Future<Database> get _db async => await AppDatabase.database;

  Future<void> insertOrUpdate(HttpTTS tts) async {
    final db = await _db;
    final map = tts.toJson();
    map['enabledCookieJar'] = (map['enabledCookieJar'] == true) ? 1 : 0;
    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HttpTTS>> getAll() async {
    final db = await _db;
    final maps = await db.query(tableName);
    return maps.map((m) {
      final map = Map<String, dynamic>.from(m);
      map['enabledCookieJar'] = map['enabledCookieJar'] == 1;
      return HttpTTS.fromJson(map);
    }).toList();
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
