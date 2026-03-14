import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../dao/bookmark_dao.dart';
import '../dao/cache_dao.dart';
import '../dao/read_record_dao.dart';
import '../dao/book_group_dao.dart';
import '../dao/rss_source_dao.dart';
import '../dao/rss_article_dao.dart';
import '../dao/dict_rule_dao.dart';
import '../dao/http_tts_dao.dart';
import '../dao/rss_star_dao.dart';
import '../dao/rule_sub_dao.dart';
import '../dao/search_keyword_dao.dart';
import '../dao/txt_toc_rule_dao.dart';
import '../dao/rss_read_record_dao.dart';
import '../dao/keyboard_assist_dao.dart';

/// AppDatabase 的表結構定義
mixin DatabaseSchema {
  Future<void> onCreate(Database db, int version) async {
    final batch = db.batch();
    debugPrint('Database: Creating core tables...');
    
    batch.execute('''CREATE TABLE IF NOT EXISTS book_sources (bookSourceUrl TEXT PRIMARY KEY, bookSourceName TEXT NOT NULL, bookSourceType INTEGER DEFAULT 0, bookSourceGroup TEXT, bookSourceComment TEXT, loginUrl TEXT, loginUi TEXT, loginCheckJs TEXT, coverDecodeJs TEXT, bookUrlPattern TEXT, header TEXT, variableComment TEXT, variable TEXT, customOrder INTEGER DEFAULT 0, weight INTEGER DEFAULT 0, enabled INTEGER DEFAULT 1, enabledExplore INTEGER DEFAULT 1, enabledCookieJar INTEGER DEFAULT 0, lastUpdateTime INTEGER DEFAULT 0, respondTime INTEGER DEFAULT 180000, jsLib TEXT, concurrentRate INTEGER DEFAULT 0, ruleSearch TEXT, ruleExplore TEXT, ruleBookInfo TEXT, ruleToc TEXT, ruleContent TEXT, ruleReview TEXT, exploreUrl TEXT, exploreScreen TEXT, searchUrl TEXT)''');
    batch.execute('''CREATE TABLE IF NOT EXISTS books (bookUrl TEXT PRIMARY KEY, name TEXT NOT NULL, author TEXT, kind TEXT, customTag TEXT, coverUrl TEXT, customCoverUrl TEXT, intro TEXT, customIntro TEXT, charset TEXT, wordCount TEXT, latestChapterTitle TEXT, latestChapterTime INTEGER DEFAULT 0, lastCheckTime INTEGER DEFAULT 0, lastCheckCount INTEGER DEFAULT 0, totalChapterNum INTEGER DEFAULT 0, durChapterIndex INTEGER DEFAULT 0, durChapterPos INTEGER DEFAULT 0, durChapterTitle TEXT, durChapterTime INTEGER DEFAULT 0, tocUrl TEXT DEFAULT '', infoHtml TEXT, tocHtml TEXT, origin TEXT NOT NULL, originName TEXT, originOrder INTEGER DEFAULT 0, type INTEGER DEFAULT 0, "group" INTEGER DEFAULT 0, "order" INTEGER DEFAULT 0, canUpdate INTEGER DEFAULT 1, variable TEXT, readConfig TEXT, syncTime INTEGER DEFAULT 0, isInBookshelf INTEGER DEFAULT 0)''');
    batch.execute('''CREATE TABLE IF NOT EXISTS chapters (url TEXT NOT NULL, title TEXT NOT NULL, bookUrl TEXT NOT NULL, baseUrl TEXT DEFAULT '', "index" INTEGER NOT NULL, isVolume INTEGER DEFAULT 0, isVip INTEGER DEFAULT 0, isPay INTEGER DEFAULT 0, resourceUrl TEXT, tag TEXT, wordCount TEXT, start INTEGER, end INTEGER, variable TEXT, startFragmentId TEXT, endFragmentId TEXT, PRIMARY KEY (bookUrl, "index"))''');
    batch.execute('''CREATE TABLE IF NOT EXISTS chapter_contents (bookUrl TEXT NOT NULL, chapterIndex INTEGER NOT NULL, content TEXT, PRIMARY KEY (bookUrl, chapterIndex))''');
    batch.execute('''CREATE TABLE IF NOT EXISTS replace_rules (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, "group" TEXT, pattern TEXT NOT NULL, replacement TEXT DEFAULT '', scope TEXT, scopeTitle INTEGER DEFAULT 0, scopeContent INTEGER DEFAULT 1, excludeScope TEXT, isEnabled INTEGER DEFAULT 1, isRegex INTEGER DEFAULT 1, timeoutMillisecond INTEGER DEFAULT 3000, "order" INTEGER DEFAULT 0)''');
    batch.execute('''CREATE TABLE IF NOT EXISTS download_tasks (bookUrl TEXT PRIMARY KEY, bookName TEXT, startChapterIndex INTEGER, endChapterIndex INTEGER, currentChapterIndex INTEGER DEFAULT 0, status INTEGER DEFAULT 0, totalCount INTEGER DEFAULT 0, successCount INTEGER DEFAULT 0, errorCount INTEGER DEFAULT 0, lastUpdateTime INTEGER DEFAULT 0)''');
    batch.execute('''CREATE TABLE IF NOT EXISTS search_history (id INTEGER PRIMARY KEY AUTOINCREMENT, keyword TEXT NOT NULL UNIQUE, searchTime INTEGER NOT NULL)''');
    batch.execute('''CREATE TABLE IF NOT EXISTS cookies (url TEXT PRIMARY KEY, cookie TEXT NOT NULL)''');

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
}
