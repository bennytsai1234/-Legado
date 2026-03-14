import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/services/app_log_service.dart';
import '../dao/txt_toc_rule_dao.dart';
import '../dao/http_tts_dao.dart';

/// AppDatabase 的版本升級邏輯
mixin DatabaseMigrations {
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Database: Upgrading from $oldVersion to $newVersion');
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      try {
        switch (i) {
          case 2:
            await db.execute('DROP TABLE IF EXISTS txt_toc_rules');
            await db.execute(TxtTocRuleDao.createTableQuery());
            break;
          case 3:
            await db.execute('ALTER TABLE books ADD COLUMN tocUrl TEXT DEFAULT ""');
            await db.execute('ALTER TABLE books ADD COLUMN infoHtml TEXT');
            await db.execute('ALTER TABLE books ADD COLUMN tocHtml TEXT');
            break;
          case 4:
            await _runSafe(db, 'ALTER TABLE chapters ADD COLUMN startFragmentId TEXT');
            await _runSafe(db, 'ALTER TABLE chapters ADD COLUMN endFragmentId TEXT');
            break;
          case 5:
            await db.execute('DROP TABLE IF EXISTS http_tts');
            await db.execute(HttpTtsDao.createTableQuery());
            break;
          case 6:
            await _runSafe(db, 'ALTER TABLE books ADD COLUMN customTag TEXT');
            await _runSafe(db, 'ALTER TABLE books ADD COLUMN customCoverUrl TEXT');
            await _runSafe(db, 'ALTER TABLE books ADD COLUMN customIntro TEXT');
            await _runSafe(db, 'ALTER TABLE books ADD COLUMN charset TEXT');
            await _runSafe(db, 'ALTER TABLE books ADD COLUMN syncTime INTEGER DEFAULT 0');
            break;
          case 7:
            await _runSafe(db, 'ALTER TABLE chapters ADD COLUMN baseUrl TEXT DEFAULT ""');
            await _runSafe(db, 'ALTER TABLE chapters ADD COLUMN wordCount TEXT');
            await _runSafe(db, 'ALTER TABLE chapters ADD COLUMN start INTEGER');
            await _runSafe(db, 'ALTER TABLE chapters ADD COLUMN "end" INTEGER');
            break;
          case 8:
            await _runSafe(db, 'ALTER TABLE book_sources ADD COLUMN coverDecodeJs TEXT');
            await _runSafe(db, 'ALTER TABLE book_sources ADD COLUMN exploreScreen TEXT');
            await _runSafe(db, 'ALTER TABLE book_sources ADD COLUMN ruleReview TEXT');
            break;
          case 9:
            await _runSafe(db, 'ALTER TABLE replace_rules ADD COLUMN scopeTitle INTEGER DEFAULT 0');
            await _runSafe(db, 'ALTER TABLE replace_rules ADD COLUMN excludeScope TEXT');
            await _runSafe(db, 'ALTER TABLE replace_rules ADD COLUMN timeoutMillisecond INTEGER DEFAULT 3000');
            break;
          case 10:
            await db.execute('DROP TABLE IF EXISTS download_tasks');
            await db.execute('''CREATE TABLE IF NOT EXISTS download_tasks (bookUrl TEXT PRIMARY KEY, bookName TEXT, startChapterIndex INTEGER, endChapterIndex INTEGER, currentChapterIndex INTEGER DEFAULT 0, status INTEGER DEFAULT 0, totalCount INTEGER DEFAULT 0, successCount INTEGER DEFAULT 0, errorCount INTEGER DEFAULT 0, lastUpdateTime INTEGER DEFAULT 0)''');
            break;
          case 11:
            await _runSafe(db, 'ALTER TABLE bookmarks ADD COLUMN bookText TEXT');
            break;
        }
        debugPrint('Database: Migration to version $i successful');
      } catch (e, stack) {
        AppLog.put('Database Migration Error', error: e, stackTrace: stack);
        debugPrint('Database: Migration to version $i failed: $e');
      }
    }
  }

  Future<void> _runSafe(Database db, String sql) async {
    try { await db.execute(sql); } catch (_) {}
  }
}
