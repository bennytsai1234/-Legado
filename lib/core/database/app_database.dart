/// AppDatabase - 本地資料庫管理
/// 對應 Android: data/AppDatabase.kt
library;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Core tables
    await db.execute('''
      CREATE TABLE book_sources (
        bookSourceUrl TEXT PRIMARY KEY,
        bookSourceName TEXT NOT NULL,
        bookSourceType INTEGER DEFAULT 0,
        bookSourceGroup TEXT,
        bookSourceComment TEXT,
        loginUrl TEXT,
        loginUi TEXT,
        loginCheckJs TEXT,
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

    await db.execute('''
      CREATE TABLE books (
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

    await db.execute('''
      CREATE TABLE chapters (
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

    await db.execute('''
      CREATE TABLE chapter_contents (
        bookUrl TEXT NOT NULL,
        chapterIndex INTEGER NOT NULL,
        content TEXT,
        PRIMARY KEY (bookUrl, chapterIndex)
      )
    ''');

    await db.execute('''
      CREATE TABLE replace_rules (
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

    await db.execute('''
      CREATE TABLE download_tasks (
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

    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        keyword TEXT NOT NULL UNIQUE,
        searchTime INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cookies (
        url TEXT PRIMARY KEY,
        cookie TEXT NOT NULL
      )
    ''');

    // DAO Tables
    await db.execute(BookmarkDao.createTableQuery());
    await db.execute(CacheDao.createTableQuery());
    await db.execute(ReadRecordDao.createTableQuery());
    await db.execute(BookGroupDao.createTableQuery());
    await db.execute(RssSourceDao.createTableQuery());
    await db.execute(RssArticleDao.createTableQuery());
    await db.execute(DictRuleDao.createTableQuery());
    await db.execute(HttpTtsDao.createTableQuery());
    await db.execute(RssStarDao.createTableQuery());
    await db.execute(RuleSubDao.createTableQuery());
    await db.execute(SearchKeywordDao.createTableQuery());
    await db.execute(TxtTocRuleDao.createTableQuery());
    await db.execute(RssReadRecordDao.createTableQuery());
    await db.execute(KeyboardAssistDao.createTableQuery());
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Database: Upgrading from $oldVersion to $newVersion');
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      debugPrint('Database: Executing migration to version $i');
      try {
        switch (i) {
          case 2:
            // Recreate txt_toc_rules table to fix missing columns (example, serialNumber, enable)
            await db.execute('DROP TABLE IF EXISTS txt_toc_rules');
            await db.execute(TxtTocRuleDao.createTableQuery());
            break;
          case 3:
            await db.execute('ALTER TABLE books ADD COLUMN tocUrl TEXT DEFAULT ""');
            await db.execute('ALTER TABLE books ADD COLUMN infoHtml TEXT');
            await db.execute('ALTER TABLE books ADD COLUMN tocHtml TEXT');
            break;
          case 4:
            try { await db.execute('ALTER TABLE chapters ADD COLUMN startFragmentId TEXT'); } catch (_) {}
            try { await db.execute('ALTER TABLE chapters ADD COLUMN endFragmentId TEXT'); } catch (_) {}
            break;
          case 5:
            // Ensure http_tts table exists
            await db.execute('DROP TABLE IF EXISTS http_tts');
            await db.execute(HttpTtsDao.createTableQuery());
            break;
          case 6:
            // Add missing fields to books table
            try { await db.execute('ALTER TABLE books ADD COLUMN customTag TEXT'); } catch (_) {}
            try { await db.execute('ALTER TABLE books ADD COLUMN customCoverUrl TEXT'); } catch (_) {}
            try { await db.execute('ALTER TABLE books ADD COLUMN customIntro TEXT'); } catch (_) {}
            try { await db.execute('ALTER TABLE books ADD COLUMN charset TEXT'); } catch (_) {}
            try { await db.execute('ALTER TABLE books ADD COLUMN syncTime INTEGER DEFAULT 0'); } catch (_) {}
            break;
          case 7:
            // Add missing fields to chapters table
            try { await db.execute('ALTER TABLE chapters ADD COLUMN baseUrl TEXT DEFAULT ""'); } catch (_) {}
            try { await db.execute('ALTER TABLE chapters ADD COLUMN wordCount TEXT'); } catch (_) {}
            try { await db.execute('ALTER TABLE chapters ADD COLUMN start INTEGER'); } catch (_) {}
            try { await db.execute('ALTER TABLE chapters ADD COLUMN "end" INTEGER'); } catch (_) {}
            break;
          case 8:
            // Add missing fields to book_sources table
            try { await db.execute('ALTER TABLE book_sources ADD COLUMN coverDecodeJs TEXT'); } catch (_) {}
            try { await db.execute('ALTER TABLE book_sources ADD COLUMN exploreScreen TEXT'); } catch (_) {}
            try { await db.execute('ALTER TABLE book_sources ADD COLUMN ruleReview TEXT'); } catch (_) {}
            break;
          case 9:
            // Add missing fields to replace_rules table
            try { await db.execute('ALTER TABLE replace_rules ADD COLUMN scopeTitle INTEGER DEFAULT 0'); } catch (_) {}
            try { await db.execute('ALTER TABLE replace_rules ADD COLUMN excludeScope TEXT'); } catch (_) {}
            try { await db.execute('ALTER TABLE replace_rules ADD COLUMN timeoutMillisecond INTEGER DEFAULT 3000'); } catch (_) {}
            break;
          case 10:
            // Ensure download_tasks table exists
            await db.execute('DROP TABLE IF EXISTS download_tasks');
            await db.execute('''
              CREATE TABLE download_tasks (
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
            // Add bookText to bookmarks table
            try { await db.execute('ALTER TABLE bookmarks ADD COLUMN bookText TEXT'); } catch (_) {}
            break;
        }
        debugPrint('Database: Migration to version $i successful');
      } catch (e) {
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
