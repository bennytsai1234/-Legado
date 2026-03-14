import 'dart:async';
import 'package:html_unescape/html_unescape.dart';
import '../parsers/analyze_by_css.dart';
import '../parsers/analyze_by_json_path.dart';
import '../parsers/analyze_by_xpath.dart';
import '../js/js_engine.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/rule_data_interface.dart';

// 導入同目錄下的其它部分
import 'analyze_rule_support.dart';

/// AnalyzeRule 的基礎結構部分
/// 對應 Android: model/analyzeRule/AnalyzeRule.kt
abstract class AnalyzeRuleBase {
  RuleDataInterface? ruleData;
  dynamic source; // BaseSource equivalent

  // 全域調試日誌流
  static StreamController<String>? debugLogController;

  void log(String msg) {
    if (debugLogController != null && !debugLogController!.isClosed) {
      debugLogController!.add(msg);
    }
  }

  dynamic content;
  String? baseUrl;
  String? redirectUrl;
  dynamic chapter;
  String? nextChapterUrl;
  int page = 1;

  AnalyzeByXPath? analyzeByXPath;
  AnalyzeByCss? analyzeByJSoup;
  AnalyzeByJsonPath? analyzeByJSonPath;
  JsEngine? jsEngine;

  static final HtmlUnescape htmlUnescape = HtmlUnescape();
  static final Map<String, RegExp> regexCache = {};
  static final Map<String, List<SourceRule>> stringRuleCache = {};
  static final Map<String, dynamic> scriptCache = {};

  void put(String key, String? value) { ruleData?.putVariable(key, value); }
  String get(String key) { return ruleData?.getVariable(key) ?? ""; }
}
