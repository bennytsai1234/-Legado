import 'package:html/dom.dart';
import 'package:xpath_selector/xpath_selector.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import '../rule_analyzer.dart';

/// AnalyzeByXPath - XPath 解析器
/// 對應 Android: model/analyzeRule/AnalyzeByXPath.kt (5KB)
///
/// 使用 Dart `xpath_selector` + `xpath_selector_html_parser` 套件
class AnalyzeByXPath {
  late HtmlXPath _xpath;

  AnalyzeByXPath(dynamic doc) {
    if (doc is Element) {
      _xpath = HtmlXPath.node(doc);
    } else if (doc is String) {
      _xpath = HtmlXPath.html(doc);
    } else {
      _xpath = HtmlXPath.html(doc.toString());
    }
  }

  /// 獲取列表
  List<XPathNode> getElements(String xPathRule) {
    if (xPathRule.isEmpty) return [];

    final ruleAnalyzes = RuleAnalyzer(xPathRule);
    final rules = ruleAnalyzes.splitRule(['&&', '||', '%%']);

    if (rules.length == 1) {
      return _xpath.query(rules[0]).nodes;
    } else {
      final results = <List<XPathNode>>[];
      for (final rl in rules) {
        final temp = getElements(rl);
        if (temp.isNotEmpty) {
          results.add(temp);
          if (ruleAnalyzes.elementsType == '||') break;
        }
      }

      if (results.isEmpty) return [];

      final result = <XPathNode>[];
      if (ruleAnalyzes.elementsType == '%%') {
        final firstListSize = results[0].length;
        for (int i = 0; i < firstListSize; i++) {
          for (final temp in results) {
            if (i < temp.length) {
              result.add(temp[i]);
            }
          }
        }
      } else {
        for (final temp in results) {
          result.addAll(temp);
        }
      }
      return result;
    }
  }

  /// 獲取所有內容列表
  List<String> getStringList(String xPathRule) {
    if (xPathRule.isEmpty) return [];

    final ruleAnalyzes = RuleAnalyzer(xPathRule);
    final rules = ruleAnalyzes.splitRule(['&&', '||', '%%']);

    if (rules.length == 1) {
      final queryResult = _xpath.query(rules[0]);
      // If the rule ends with /@attr or /text(), queryResult.attrs usually contains it
      if (rules[0].contains('/@') || rules[0].endsWith('/text()')) {
        return queryResult.attrs.whereType<String>().toList();
      } else {
        // Fallback to node text if no attribute requested
        return queryResult.nodes.map((n) => n.text?.trim() ?? "").where((t) => t.isNotEmpty).toList();
      }
    } else {
      final results = <List<String>>[];
      for (final rl in rules) {
        final temp = getStringList(rl);
        if (temp.isNotEmpty) {
          results.add(temp);
          if (ruleAnalyzes.elementsType == '||') break;
        }
      }

      if (results.isEmpty) return [];

      final result = <String>[];
      if (ruleAnalyzes.elementsType == '%%') {
        final firstListSize = results[0].length;
        for (int i = 0; i < firstListSize; i++) {
          for (final temp in results) {
            if (i < temp.length) {
              result.add(temp[i]);
            }
          }
        }
      } else {
        for (final temp in results) {
          result.addAll(temp);
        }
      }
      return result;
    }
  }

  /// 獲取合併字串
  String? getString(String rule) {
    if (rule.isEmpty) return null;
    final list = getStringList(rule);
    if (list.isEmpty) return null;
    if (list.length == 1) return list.first;
    return list.join('\n');
  }
}
