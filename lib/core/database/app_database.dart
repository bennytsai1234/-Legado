/// AppDatabase - 本地資料庫管理
/// 對應 Android: data/AppDatabase.kt
library;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:synchronized/synchronized.dart';

import '../services/app_log_service.dart';
import 'dao/bookmark_dao.dart';
import 'dao/cache_dao.dart';
import 'dao/read_record_dao.dart';
import 'dao/book_group_dao.dart';
import 'dao/rss_source_dao.dart';
import 'dao/rss_article_dao.dart';
import 'dao/dict_rule_dao.dart';
import 'dao/http_tts_dao.dart';
import 'dao/rss_star_dao.dart';
import 'dao/rule_sub_dao.dart';
import 'dao/search_keyword_dao.dart';
import 'dao/txt_toc_rule_dao.dart';
import 'dao/rss_read_record_dao.dart';
import 'dao/keyboard_assist_dao.dart';

class AppDatabase {
  static const String _dbName = 'legado_reader.db';
  static const int _dbVersion = 11;
  static Database? _database;
  static final _lock = Lock();

  static Future<Database> get database async {
    final db = _database;
    if (db != null && db.isOpen) return db;
    
    return await _lock.synchronized(() async {
      if (_database != null && _database!.isOpen) return _database!;
      debugPrint('Database: Starting initialization...');
      try {
        _database = await _initDatabase();
      } catch (e) {
        debugPrint('Database: First initialization attempt failed: $e');
        // 如果是因為併發導致的事務錯誤 (如 "no current transaction" 或 "database is locked")
        // 這通常是因為另一個 Isolate 正在或已經完成了初始化
        if (e.toString().contains('no current transaction') || 
            e.toString().contains('database is locked')) {
          await Future.delayed(const Duration(milliseconds: 500));
          _database = await _initDatabase();
        } else {
          rethrow;
        }
      }
      debugPrint('Database: Initialization completed.');
      return _database!;
    });
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        debugPrint('Database: onCreate started (version: $version)');
        await _onCreate(db, version);
        debugPrint('Database: onCreate finished');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint('Database: onUpgrade started ($oldVersion -> $newVersion)');
        await _onUpgrade(db, oldVersion, newVersion);
        debugPrint('Database: onUpgrade finished');
      },
      onOpen: (db) {
        debugPrint('Database: onOpen - Database is now open');
      }
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    // Core tables
    debugPrint('Database: Creating core tables...');
    batch.execute('''
      CREATE TABLE IF NOT EXISTS book_sources (
        bookSourceUrl TEXT PRIMARY KEY,
        bookSourceName TEXT NOT NULL,
        bookSourceType INTEGER DEFAULT 0,
        bookSourceGroup TEXT,
        bookSourceComment TEXT,
        loginUrl TEXT,
        loginUi TEXT,
        loginCheckJs TEXT,
        coverDecodeJs TEXT,
        bookUrlPattern TEXT,
        header TEXT,
        variableComment TEXT,
        variable TEXT,
        customOrder INTEGER DEFAULT 0,
        weight INTEGER DEFAULT 0,
        enabled INTEGER DEFAULT 1,
        enabledExplore INTEGER DEFAULT 1,
        enabledCookieJar INTEGER DEFAULT 0,
        lastUpdateTime INTEGER DEFAULT 0,
        respondTime INTEGER DEFAULT 180000,
        jsLib TEXT,
        concurrentRate INTEGER DEFAULT 0,
        ruleSearch TEXT,
        ruleExplore TEXT,
        ruleBookInfo TEXT,
        ruleToc TEXT,
        ruleContent TEXT,
        ruleReview TEXT,
        exploreUrl TEXT,
        exploreScreen TEXT,
        searchUrl TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS books (
        bookUrl TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        author TEXT,
        kind TEXT,
        customTag TEXT,
        coverUrl TEXT,
        customCoverUrl TEXT,
        intro TEXT,
        customIntro TEXT,
        charset TEXT,
        wordCount TEXT,
        latestChapterTitle TEXT,
        latestChapterTime INTEGER DEFAULT 0,
        lastCheckTime INTEGER DEFAULT 0,
        lastCheckCount INTEGER DEFAULT 0,
        totalChapterNum INTEGER DEFAULT 0,
        durChapterIndex INTEGER DEFAULT 0,
        durChapterPos INTEGER DEFAULT 0,
        durChapterTitle TEXT,
        durChapterTime INTEGER DEFAULT 0,
        tocUrl TEXT DEFAULT '',
        infoHtml TEXT,
        tocHtml TEXT,
        origin TEXT NOT NULL,
        originName TEXT,
        originOrder INTEGER DEFAULT 0,
        type INTEGER DEFAULT 0,
        "group" INTEGER DEFAULT 0,
        "order" INTEGER DEFAULT 0,
        canUpdate INTEGER DEFAULT 1,
        variable TEXT,
        readConfig TEXT,
        syncTime INTEGER DEFAULT 0,
        isInBookshelf INTEGER DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS chapters (
        url TEXT NOT NULL,
        title TEXT NOT NULL,
        bookUrl TEXT NOT NULL,
        baseUrl TEXT DEFAULT '',
        "index" INTEGER NOT NULL,
        isVolume INTEGER DEFAULT 0,
        isVip INTEGER DEFAULT 0,
        isPay INTEGER DEFAULT 0,
        resourceUrl TEXT,
        tag TEXT,
        wordCount TEXT,
        start INTEGER,
        end INTEGER,
        variable TEXT,
        startFragmentId TEXT,
        endFragmentId TEXT,
        PRIMARY KEY (bookUrl, "index")
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS chapter_contents (
        bookUrl TEXT NOT NULL,
        chapterIndex INTEGER NOT NULL,
        content TEXT,
        PRIMARY KEY (bookUrl, chapterIndex)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS replace_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        "group" TEXT,
        pattern TEXT NOT NULL,
        replacement TEXT DEFAULT '',
        scope TEXT,
        scopeTitle INTEGER DEFAULT 0,
        scopeContent INTEGER DEFAULT 1,
        excludeScope TEXT,
        isEnabled INTEGER DEFAULT 1,
        isRegex INTEGER DEFAULT 1,
        timeoutMillisecond INTEGER DEFAULT 3000,
        "order" INTEGER DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS download_tasks (
        bookUrl TEXT PRIMARY KEY,
        bookName TEXT,
        startChapterIndex INTEGER,
        endChapterIndex INTEGER,
        currentChapterIndex INTEGER DEFAULT 0,
        status INTEGER DEFAULT 0,
        totalCount INTEGER DEFAULT 0,
        successCount INTEGER DEFAULT 0,
        errorCount INTEGER DEFAULT 0,
        lastUpdateTime INTEGER DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        keyword TEXT NOT NULL UNIQUE,
        searchTime INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS cookies (
        url TEXT PRIMARY KEY,
        cookie TEXT NOT NULL
      )
    ''');

    // DAO Tables
    debugPrint('Database: Creating DAO tables...');
    batch.execute(BookmarkDao.createTableQuery());
    batch.execute(CacheDao.createTableQuery());
    batch.execute(ReadRecordDao.createTableQuery());
    batch.execute(BookGroupDao.createTableQuery());
    batch.execute(RssSourceDao.createTableQuery());
    batch.execute(RssArticleDao.createTableQuery());
    batch.execute(DictRuleDao.createTableQuery());
    batch.execute(HttpTtsDao.createTableQuery());
    batch.execute(RssStarDao.createTableQuery());
    batch.execute(RuleSubDao.createTableQuery());
    batch.execute(SearchKeywordDao.createTableQuery());
    batch.execute(TxtTocRuleDao.createTableQuery());
    batch.execute(RssReadRecordDao.createTableQuery());
    batch.execute(KeyboardAssistDao.createTableQuery());

    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Database: Upgrading from $oldVersion to $newVersion');
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      debugPrint('Database: Executing migration to version $i');
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
            try { await db.execute('ALTER TABLE chapters ADD COLUMN startFragmentId TEXT'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            try { await db.execute('ALTER TABLE chapters ADD COLUMN endFragmentId TEXT'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            break;
          case 5:
            await db.execute('DROP TABLE IF EXISTS http_tts');
            await db.execute(HttpTtsDao.createTableQuery());
            break;
          case 6:
            try { await db.execute('ALTER TABLE books ADD COLUMN customTag TEXT'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            try { await db.execute('ALTER TABLE books ADD COLUMN customCoverUrl TEXT'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            try { await db.execute('ALTER TABLE books ADD COLUMN customIntro TEXT'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            try { await db.execute('ALTER TABLE books ADD COLUMN charset TEXT'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            try { await db.execute('ALTER TABLE books ADD COLUMN syncTime INTEGER DEFAULT 0'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            break;
          case 7:
            try { await db.execute('ALTER TABLE chapters ADD COLUMN baseUrl TEXT DEFAULT ""'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            try { await db.execute('ALTER TABLE chapters ADD COLUMN wordCount TEXT'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            try { await db.execute('ALTER TABLE chapters ADD COLUMN start INTEGER'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            try { await db.execute('ALTER TABLE chapters ADD COLUMN "end" INTEGER'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            break;
          case 8:
            try { await db.execute('ALTER TABLE book_sources ADD COLUMN coverDecodeJs TEXT'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            try { await db.execute('ALTER TABLE book_sources ADD COLUMN exploreScreen TEXT'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            try { await db.execute('ALTER TABLE book_sources ADD COLUMN ruleReview TEXT'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            break;
          case 9:
            try { await db.execute('ALTER TABLE replace_rules ADD COLUMN scopeTitle INTEGER DEFAULT 0'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            try { await db.execute('ALTER TABLE replace_rules ADD COLUMN excludeScope TEXT'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            try { await db.execute('ALTER TABLE replace_rules ADD COLUMN timeoutMillisecond INTEGER DEFAULT 3000'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            break;
          case 10:
            await db.execute('DROP TABLE IF EXISTS download_tasks');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS download_tasks (
                bookUrl TEXT PRIMARY KEY,
                bookName TEXT,
                startChapterIndex INTEGER,
                endChapterIndex INTEGER,
                currentChapterIndex INTEGER DEFAULT 0,
                status INTEGER DEFAULT 0,
                totalCount INTEGER DEFAULT 0,
                successCount INTEGER DEFAULT 0,
                errorCount INTEGER DEFAULT 0,
                lastUpdateTime INTEGER DEFAULT 0
              )
            ''');
            break;
          case 11:
            try { await db.execute('ALTER TABLE bookmarks ADD COLUMN bookText TEXT'); } catch (e, stack) { AppLog.put('Database Migration Error', error: e, stackTrace: stack); }
            break;
        }
        debugPrint('Database: Migration to version $i successful');
      } catch (e, stack) {
        AppLog.put('Database Migration Error', error: e, stackTrace: stack);
        debugPrint('Database: Migration to version $i failed: $e');
      }
    }
    debugPrint('Database: All migrations completed');
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
