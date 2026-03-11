import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/dao/book_source_dao.dart';
import '../database/dao/txt_toc_rule_dao.dart';
import '../database/dao/http_tts_dao.dart';
import '../models/book_source.dart';
import '../models/txt_toc_rule.dart';
import '../models/http_tts.dart';

class DefaultData {
  DefaultData._();

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('is_first_run') ?? true;

    if (isFirstRun) {
      await _loadDefaultTocRules();
      await _loadDefaultHttpTts();
      await _loadDefaultSources();
      await prefs.setBool('is_first_run', false);
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
    // 預設一個示例
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
      final jsonStr = await rootBundle.loadString('assets/default_sources/sources.json').catchError((_) => "");
      if (jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        final sources = jsonList.map((j) => BookSource.fromJson(jsonAt(j))).toList();
        await dao.insertOrUpdateAll(sources);
      }
    } catch (e) {
      // 忽略錯誤
    }
  }

  static Map<String, dynamic> jsonAt(dynamic j) => Map<String, dynamic>.from(j);
}
