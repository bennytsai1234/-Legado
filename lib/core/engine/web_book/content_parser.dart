import '../../../../core/models/book_source.dart';
import '../analyze_rule.dart';

class ContentParser {
  static String parse({
    required BookSource source,
    required String body,
    required String baseUrl,
  }) {
    final rule = AnalyzeRule(source: source).setContent(body, baseUrl: baseUrl);
    final contentRule = source.ruleContent;
    if (contentRule == null) return body;

    // 取得正文內容
    String content = rule.getString(contentRule.content ?? "");
    
    return content;
  }
}
