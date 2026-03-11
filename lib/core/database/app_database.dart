/// AppDatabase - 本地資料庫管理
/// 對應 Android: data/AppDatabase.kt
library;

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
  static const int _dbVersion = 1;
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
        exploreUrl TEXT,
        searchUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE books (
        bookUrl TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        author TEXT,
        kind TEXT,
        coverUrl TEXT,
        intro TEXT,
        wordCount TEXT,
        latestChapterTitle TEXT,
        latestChapterTime INTEGER DEFAULT 0,
        lastCheckTime INTEGER DEFAULT 0,
        lastCheckCount INTEGER DEFAULT 0,
        totalChapterNum INTEGER DEFAULT 0,
        durChapterIndex INTEGER DEFAULT 0,
        durChapterPos INTEGER DEFAULT 0,
        durChapterTitle TEXT,
        durChapterTime TEXT,
        origin TEXT NOT NULL,
        originName TEXT,
        originOrder INTEGER DEFAULT 0,
        type INTEGER DEFAULT 0,
        "group" TEXT,
        "order" INTEGER DEFAULT 0,
        canUpdate INTEGER DEFAULT 1,
        variable TEXT,
        readConfig TEXT,
        isInBookshelf INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE chapters (
        url TEXT NOT NULL,
        title TEXT NOT NULL,
        bookUrl TEXT NOT NULL,
        "index" INTEGER NOT NULL,
        isVolume INTEGER DEFAULT 0,
        isVip INTEGER DEFAULT 0,
        isPay INTEGER DEFAULT 0,
        resourceUrl TEXT,
        tag TEXT,
        variable TEXT,
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
        scopeContent TEXT,
        isEnabled INTEGER DEFAULT 1,
        isRegex INTEGER DEFAULT 1,
        "order" INTEGER DEFAULT 0
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
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      switch (i) {
        case 2:
          break;
      }
    }
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
