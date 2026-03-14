import 'package:legado_reader/core/models/rule_data_interface.dart';

// 導入拆分後的模組
import 'analyze_rule/analyze_rule_base.dart';

export 'analyze_rule/analyze_rule_base.dart';
export 'analyze_rule/analyze_rule_support.dart';
export 'analyze_rule/analyze_rule_core.dart';
export 'analyze_rule/analyze_rule_script.dart';

/// AnalyzeRule - 規則總控 (重構後)
/// 對應 Android: model/analyzeRule/AnalyzeRule.kt
/// 透過 Extension 將邏輯拆分至各個子檔案
class AnalyzeRule extends AnalyzeRuleBase {
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
    if (content == null) throw ArgumentError("Content cannot be null");
    this.content = content;
    this.baseUrl = baseUrl;
    analyzeByXPath = null;
    analyzeByJSoup = null;
    analyzeByJSonPath = null;
    return this;
  }

  @override
  dynamic evalJS(String jsStr, dynamic result) {
    return (this).evalJS(jsStr, result);
  }

  // 靜態輔助方法 (如果需要)
  static String getUtilsJs() {
    return "";
  }
}
