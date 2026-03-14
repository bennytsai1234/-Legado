import 'package:sqflite/sqflite.dart';
import 'db/database_base.dart';
import 'db/database_schema.dart';
import 'db/database_migrations.dart';

/// AppDatabase - 本地資料庫管理 (重構後)
/// 對應 Android: data/AppDatabase.kt
class AppDatabase extends DatabaseBase with DatabaseSchema, DatabaseMigrations {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  /// 獲取資料庫實例
  static Future<Database> get database async {
    return await DatabaseBase.getDatabase(
      onCreate: _instance.onCreate,
      onUpgrade: _instance.onUpgrade,
    );
  }

  /// 關閉資料庫
  static Future<void> close() async {
    await DatabaseBase.closeDatabase();
  }
}
