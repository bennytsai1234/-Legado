import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../database/dao/book_source_dao.dart';
import '../database/dao/txt_toc_rule_dao.dart';
import '../database/dao/http_tts_dao.dart';
import '../models/book_source.dart';
import '../models/txt_toc_rule.dart';
import '../models/http_tts.dart';
import 'chinese_utils.dart';
import 'webdav_service.dart';

class DefaultData {
  DefaultData._();

  static Future<void> init() async {
    // 1. 確保資料庫初始化 (對應 Android appDb 初始化)
    await AppDatabase.database;

    final prefs = await SharedPreferences.getInstance();
    final currentDataVersion = 1; // Increment this when default data changes
    final savedDataVersion = prefs.getInt('default_data_version') ?? 0;

    if (savedDataVersion < currentDataVersion) {
      await _loadDefaultTocRules();
      await _loadDefaultHttpTts();
      await _loadDefaultSources();
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
      // 這裡可以根據 bookUrl 是否仍存在於 books 表來判斷
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

  static Future<void> _loadDefaultTocRules() async {
    final dao = TxtTocRuleDao();
    final defaultRules = [
      TxtTocRule(id: 0, name: "標準章節", rule: r"第[一二三四五六七八九十百千萬零\d]+[章回節卷集幕計].*", enable: true),
      TxtTocRule(id: 0, name: "數字章節", rule: r"^\s*\d+.*", enable: true),
    ];
    for (final rule in defaultRules) {
      await dao.insertOrUpdate(rule);
    }
  }

  static Future<void> _loadDefaultHttpTts() async {
    final dao = HttpTtsDao();
    final sampleTts = HttpTTS(
      id: 0,
      name: "預設語音 (示例)",
      url: "https://api.example.com/tts?text={{speakText}}",
    );
    await dao.insertOrUpdate(sampleTts);
  }

  static Future<void> _loadDefaultSources() async {
    try {
      final dao = BookSourceDao();
      // 使用 try-catch 包裹，確保如果 assets 缺失不影響後續啟動
      String jsonStr = "";
      try {
        jsonStr = await rootBundle.loadString('assets/default_sources/sources.json');
      } catch (e) {
        debugPrint("Default Sources Asset Not Found: sources.json");
      }

      if (jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        final sources = jsonList.map((j) => BookSource.fromJson(jsonAt(j))).toList();     
        await dao.insertOrUpdateAll(sources);
      }
    } catch (e) {
      debugPrint("Error loading default sources: $e");
    }
  }
  static Map<String, dynamic> jsonAt(dynamic j) => Map<String, dynamic>.from(j);
}
