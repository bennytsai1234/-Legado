import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/rule_data_interface.dart';

// 導入拆分後的模組
import 'analyze_rule/analyze_rule_base.dart';
import 'analyze_rule/analyze_rule_core.dart';
import 'analyze_rule/analyze_rule_script.dart';
import 'analyze_rule/analyze_rule_support.dart';
import 'analyze_rule/analyze_rule_element.dart';
import 'analyze_rule/analyze_rule_string.dart';
import 'analyze_rule/analyze_rule_regex_helper.dart';

export 'analyze_rule/analyze_rule_base.dart';
export 'analyze_rule/analyze_rule_support.dart';
export 'analyze_rule/analyze_rule_core.dart';
export 'analyze_rule/analyze_rule_script.dart';
export 'analyze_rule/analyze_rule_element.dart';
export 'analyze_rule/analyze_rule_string.dart';
export 'analyze_rule/analyze_rule_regex_helper.dart';

/// AnalyzeRule - 規則總控 (重構後)
/// 對應 Android: model/analyzeRule/AnalyzeRule.kt
class AnalyzeRule extends AnalyzeRuleBase with AnalyzeRuleRegexHelper, AnalyzeRuleElement, AnalyzeRuleString {
  AnalyzeRule({RuleDataInterface? ruleData, dynamic source}) {
    this.ruleData = ruleData;
    this.source = source;
  }

  AnalyzeRule setChapter(dynamic chapter) {
    this.chapter = chapter;
    return this;
  }

  AnalyzeRule setNextChapterUrl(String? nextChapterUrl) {
    this.nextChapterUrl = nextChapterUrl;
    return this;
  }

  AnalyzeRule setPage(int page) {
    this.page = page;
    return this;
  }

  AnalyzeRule setRedirectUrl(String? url) {
    if (url != null && url.isNotEmpty) {
      redirectUrl = url;
    }
    return this;
  }

  AnalyzeRule setContent(dynamic content, {String? baseUrl}) {
    if (content == null) {
      throw ArgumentError("Content cannot be null");
    }
    this.content = content;
    this.baseUrl = baseUrl;
    analyzeByXPath = null;
    analyzeByJSoup = null;
    analyzeByJSonPath = null;
    return this;
  }

  @override
  dynamic evalJS(String jsStr, dynamic result) {
    return (this as AnalyzeRule).evalJS(jsStr, result);
  }

  // 靜態輔助方法 (如果需要)
  static String getUtilsJs() {
    return "";
  }
}
