import 'package:sqflite/sqflite.dart';
import '../../models/rss_read_record.dart';
import '../app_database.dart';

class RssReadRecordDao {
  static const String tableName = 'rss_read_records';

  static String createTableQuery() {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        origin TEXT NOT NULL,
        link TEXT NOT NULL,
        readTime INTEGER DEFAULT 0,
        PRIMARY KEY (origin, link)
      )
    ''';
  }

  Future<Database> get _db async => await AppDatabase.database;

  Future<void> insert(RssReadRecord record) async {
    final db = await _db;
    await db.insert(
      tableName,
      record.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
