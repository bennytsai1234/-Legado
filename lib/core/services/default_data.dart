import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../database/dao/book_source_dao.dart';
import '../database/dao/txt_toc_rule_dao.dart';
import '../database/dao/http_tts_dao.dart';
import '../database/dao/rss_source_dao.dart';
import '../database/dao/dict_rule_dao.dart';
import '../models/book_source.dart';
import '../models/txt_toc_rule.dart';
import '../models/http_tts.dart';
import '../models/rss_source.dart';
import '../models/dict_rule.dart';
import 'chinese_utils.dart';
import 'webdav_service.dart';

/// DefaultData - 預設資料初始化
/// 對應 Android: help/DefaultData.kt
class DefaultData {
  DefaultData._();

  static Future<void> init() async {
    // 1. 確保資料庫初始化 (對應 Android appDb 初始化)
    await AppDatabase.database;

    final prefs = await SharedPreferences.getInstance();
    // 對標 Android versionCode 判斷
    final currentDataVersion = 100; 
    final savedDataVersion = prefs.getInt('default_data_version') ?? 0;

    if (savedDataVersion < currentDataVersion) {
      await _loadDefaultTocRules();
      await _loadDefaultHttpTts();
      await _loadDefaultSources();
      await _loadDefaultRssSources();
      await _loadDefaultDictRules();
      await prefs.setInt('default_data_version', currentDataVersion);
    }

    // 2. 啟動時維護與清理 (對應 Android App.onCreate 中的各式 Clear 與 adjustSortNumber)
    await _maintenance();

    // 3. 預熱與同步 (對應 Android ChineseUtils.preLoad 與 AppWebDav 同步)
    _startBackgroundTasks(prefs);
  }

  static Future<void> _maintenance() async {
    try {
      // 校正書源排序 (對應 Android SourceHelp.adjustSortNumber)
      await BookSourceDao().adjustSortNumbers();

      // 清理過期資料 (對應 Android appDb.cacheDao.clearDeadline)
      final db = await AppDatabase.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // 清理超過 7 天的搜尋歷史
      final sevenDaysAgo = now - (7 * 24 * 60 * 60 * 1000);
      await db.delete('search_history', where: 'searchTime < ?', whereArgs: [sevenDaysAgo]);
      
      // 清理無效的章節快取內容 (對應 Android BookHelp.clearInvalidCache)
      await db.execute('''
        DELETE FROM chapter_contents 
        WHERE bookUrl NOT IN (SELECT bookUrl FROM books)
      ''');

    } catch (e) {
      // 忽略維護錯誤
    }
  }

  static void _startBackgroundTasks(SharedPreferences prefs) {
    // A. 預熱簡繁轉換 (對應 Android ChineseUtils.preLoad)
    ChineseUtils.s2t("");

    // B. 自動 WebDAV 同步 (對應 Android AppWebDav.downloadAllBookProgress)
    final webdavEnabled = prefs.getBool('webdav_enabled') ?? false;
    if (webdavEnabled) {
      WebDAVService().restore(); // 異步執行同步還原
    }
  }

  /// 載入預設目錄規則 (對標 importDefaultTocRules)
  static Future<void> _loadDefaultTocRules() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/default_sources/txtTocRule.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      final rules = list.map((e) => TxtTocRule.fromJson(e)).toList();
      await TxtTocRuleDao().insertOrUpdateAll(rules);
    } catch (e) {
      // 如果 Asset 缺失，回退到基礎硬編碼規則 (對標 Android 應急邏輯)
      final defaultRules = [
        TxtTocRule(id: 0, name: "標準章節", rule: r"第[一二三四五六七八九十百千萬零\d]+[章回節卷集幕計].*", enable: true),
        TxtTocRule(id: 0, name: "數字章節", rule: r"^\s*\d+.*", enable: true),
      ];
      for (final rule in defaultRules) {
        await TxtTocRuleDao().insertOrUpdate(rule);
      }
    }
  }

  /// 載入預設 HTTP TTS (對標 importDefaultHttpTTS)
  static Future<void> _loadDefaultHttpTts() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/default_sources/httpTTS.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      final engines = list.map((e) => HttpTTS.fromJson(e)).toList();
      await HttpTtsDao().insertOrUpdateAll(engines);
    } catch (e) {
      debugPrint("Default HttpTTS Asset Not Found");
    }
  }

  /// 載入預設書源
  static Future<void> _loadDefaultSources() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/default_sources/sources.json');
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final sources = jsonList.map((j) => BookSource.fromJson(jsonAt(j))).toList();     
      await BookSourceDao().insertOrUpdateAll(sources);
    } catch (e) {
      debugPrint("Error loading default sources: $e");
    }
  }

  /// 載入預設 RSS 源 (對標 importDefaultRssSources)
  static Future<void> _loadDefaultRssSources() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/default_sources/rssSources.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      final sources = list.map((e) => RssSource.fromJson(e)).toList();
      await RssSourceDao().insertOrUpdateAll(sources);
    } catch (e) {
      debugPrint("Default RssSources Asset Not Found");
    }
  }

  /// 載入預設字典規則 (對標 importDefaultDictRules)
  static Future<void> _loadDefaultDictRules() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/default_sources/dictRules.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      final rules = list.map((e) => DictRule.fromJson(e)).toList();
      await DictRuleDao().insertOrUpdateAll(rules);
    } catch (e) {
      debugPrint("Default DictRules Asset Not Found");
    }
  }

  static Map<String, dynamic> jsonAt(dynamic j) => Map<String, dynamic>.from(j);
}
