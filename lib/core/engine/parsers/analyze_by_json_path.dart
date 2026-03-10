import 'dart:convert';
import 'package:json_path/json_path.dart';
import '../rule_analyzer.dart';

/// AnalyzeByJsonPath - JsonPath 解析器
/// 對應 Android: model/analyzeRule/AnalyzeByJSonPath.kt (6KB)
///
/// 使用 Dart `json_path` 套件
class AnalyzeByJsonPath {
  dynamic _jsonData;

  AnalyzeByJsonPath([dynamic json]) {
    if (json != null) {
      setContent(json);
    }
  }

  void setContent(dynamic content) {
    if (content is String) {
      try {
        _jsonData = jsonDecode(content);
      } catch (e) {
        _jsonData = content;
      }
    } else {
      _jsonData = content;
    }
  }

  /// 預處理規則，去除 @json: 前綴
  String _preProcessRule(String rule) {
    rule = rule.trim();
    if (rule.toLowerCase().startsWith('@json:')) {
      return rule.substring(6).trim();
    }
    return rule;
  }

  /// Get a string result from JsonPath
  String? getString(String rule) {
    rule = _preProcessRule(rule);
    if (rule.isEmpty) return null;

    final ruleAnalyzer = RuleAnalyzer(rule, isCode: true);
    final rules = ruleAnalyzer.splitRule(['&&', '||']);

    if (rules.length == 1) {
      ruleAnalyzer.reSetPos();
      // 替換所有 {$.rule...}
      String result = ruleAnalyzer.innerRule(r'{$.', fr: (it) => getString(it));

      if (result.isEmpty) {
        try {
          final path = JsonPath(rule);
          final matches = path.read(_jsonData);
          if (matches.isEmpty) return null;

          final values = matches.map((m) => m.value).toList();
          if (values.length == 1) {
            return values[0].toString(); // 自動轉字串 (含數字)
          } else {
            return values.map((v) => v.toString()).join('\n');
          }
        } catch (e) {
          return null;
        }
      }
      return result;
    } else {
      final textList = <String>[];
      for (final rl in rules) {
        final temp = getString(rl);
        if (temp != null && temp.isNotEmpty) {
          textList.add(temp);
          if (ruleAnalyzer.elementsType == '||') {
            break;
          }
        }
      }
      return textList.isEmpty ? null : textList.join('\n');
    }
  }

  /// Get a list of elements matching the JsonPath
  List<dynamic> getElements(String rule) {
    rule = _preProcessRule(rule);
    if (rule.isEmpty) return [];

    final ruleAnalyzer = RuleAnalyzer(rule, isCode: true);
    final rules = ruleAnalyzer.splitRule(['&&', '||', '%%']);

    if (rules.length == 1) {
      try {
        final path = JsonPath(rules[0]);
        final matches = path.read(_jsonData);
        final result = matches.map((m) => m.value).toList();
        // If it's a list of lists, flatten it if it matches Legado's behavior
        // Android returns ctx.read<ArrayList<Any>>(rules[0])
        if (result.length == 1 && result[0] is List) {
          return result[0] as List;
        }
        return result;
      } catch (e) {
        return [];
      }
    } else {
      final results = <List<dynamic>>[];
      for (final rl in rules) {
        final temp = getElements(rl);
        if (temp.isNotEmpty) {
          results.add(temp);
          if (ruleAnalyzer.elementsType == '||') {
            break;
          }
        }
      }

      if (results.isEmpty) return [];

      final result = <dynamic>[];
      if (ruleAnalyzer.elementsType == '%%') {
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

  /// Alias for getElements to match Android naming consistency if needed
  List<dynamic> getList(String rule) => getElements(rule);

  /// Get a single object
  dynamic getObject(String rule) {
    final list = getElements(rule);
    return list.isNotEmpty ? list.first : null;
  }

  /// Get a list of strings
  List<String> getStringList(String rule) {
    final list = getElements(rule);
    return list.map((e) => e.toString()).toList();
  }
}
