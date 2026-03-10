import 'dart:convert';
import 'package:html/dom.dart';
import 'package:xpath_selector/xpath_selector.dart';
import 'parsers/analyze_by_css.dart';
import 'parsers/analyze_by_json_path.dart';
import 'parsers/analyze_by_xpath.dart';
import 'parsers/analyze_by_regex.dart';
import 'rule_analyzer.dart';

/// RuleDataInterface - 規則上下文數據介面
/// 對應 Android: model/analyzeRule/RuleDataInterface.kt
abstract class RuleDataInterface {
  Map<String, String> get variableMap;
  
  void putVariable(String key, String? value);
  String getVariable(String key);
}

/// AnalyzeRule - 規則總控
/// 對應 Android: model/analyzeRule/AnalyzeRule.kt (32KB)
class AnalyzeRule {
  RuleDataInterface? ruleData;
  dynamic source; // BaseSource equivalent
  
  dynamic _content;
  String? _baseUrl;
  bool _isJson = false;

  AnalyzeByXPath? _analyzeByXPath;
  AnalyzeByCss? _analyzeByJSoup;
  AnalyzeByJsonPath? _analyzeByJSonPath;

  AnalyzeRule({this.ruleData, this.source});

  AnalyzeRule setContent(dynamic content, {String? baseUrl}) {
    if (content == null) throw ArgumentError("Content cannot be null");
    _content = content;
    if (content is String) {
      _isJson = _checkIsJson(content);
    } else if (content is Node) {
      _isJson = false;
    } else {
      _isJson = true; // Assume Map/List is JSON
    }
    _baseUrl = baseUrl;
    _analyzeByXPath = null;
    _analyzeByJSoup = null;
    _analyzeByJSonPath = null;
    return this;
  }

  bool _checkIsJson(String str) {
    final s = str.trim();
    return (s.startsWith('{') && s.endsWith('}')) || (s.startsWith('[') && s.endsWith(']'));
  }

  AnalyzeByXPath _getAnalyzeByXPath(dynamic o) {
    if (o != _content) return AnalyzeByXPath(o);
    return _analyzeByXPath ??= AnalyzeByXPath(_content);
  }

  AnalyzeByCss _getAnalyzeByJSoup(dynamic o) {
    if (o != _content) return AnalyzeByCss(o);
    return _analyzeByJSoup ??= AnalyzeByCss(_content);
  }

  AnalyzeByJsonPath _getAnalyzeByJSonPath(dynamic o) {
    if (o != _content) return AnalyzeByJsonPath(o);
    return _analyzeByJSonPath ??= AnalyzeByJsonPath(_content);
  }

  /// 獲取列表
  List<dynamic> getElements(String ruleStr) {
    if (ruleStr.isEmpty) return [];
    
    var result = _content;
    final ruleList = splitSourceRule(ruleStr);
    
    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) break;
        // makeUpRule would handle @get, {{js}} etc.
        sourceRule.makeUpRule(result, this);
        final rule = sourceRule.rule;
        
        switch (sourceRule.mode) {
          case _Mode.regex:
            result = AnalyzeByRegex.getElements(result.toString(), rule.split('&&').where((s) => s.isNotEmpty).toList());
            break;
          case _Mode.json:
            result = _getAnalyzeByJSonPath(result).getList(rule);
            break;
          case _Mode.xpath:
            result = _getAnalyzeByXPath(result).getElements(rule);
            break;
          case _Mode.js:
            result = evalJS(rule, result);
            break;
          default:
            result = _getAnalyzeByJSoup(result).getElements(rule);
        }
      }
    }
    
    if (result is List) return result;
    if (result == null) return [];
    return [result];
  }

  /// 獲取單個字串
  String getString(String ruleStr, {bool isUrl = false}) {
    if (ruleStr.isEmpty) return "";
    
    final ruleList = splitSourceRule(ruleStr);
    var result = _content;
    
    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) break;
        sourceRule.makeUpRule(result, this);
        final rule = sourceRule.rule;
        
        if (rule.isNotEmpty || sourceRule.replaceRegex.isEmpty) {
          switch (sourceRule.mode) {
            case _Mode.js:
              result = evalJS(rule, result);
              break;
            case _Mode.json:
              result = _getAnalyzeByJSonPath(result).getString(rule);
              break;
            case _Mode.xpath:
              result = _getAnalyzeByXPath(result).getString(rule);
              break;
            case _Mode.regex:
              // Just return the rule if it's regex mode (it already replaced variables)
              result = rule;
              break;
            default:
              result = _getAnalyzeByJSoup(result).getString(rule);
          }
        }
        
        if (result != null && sourceRule.replaceRegex.isNotEmpty) {
          result = _replaceRegex(result.toString(), sourceRule);
        }
      }
    }
    
    var str = result?.toString() ?? "";
    // TODO: Unescape HTML entities if needed
    
    if (isUrl && str.isEmpty) return _baseUrl ?? "";
    // TODO: Absolute URL conversion
    return str;
  }

  /// 獲取字串列表
  List<String> getStringList(String ruleStr, {bool isUrl = false}) {
    if (ruleStr.isEmpty) return [];
    
    final ruleList = splitSourceRule(ruleStr);
    var result = _content;
    
    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) break;
        sourceRule.makeUpRule(result, this);
        final rule = sourceRule.rule;
        
        switch (sourceRule.mode) {
          case _Mode.js:
            result = evalJS(rule, result);
            break;
          case _Mode.json:
            result = _getAnalyzeByJSonPath(result).getStringList(rule);
            break;
          case _Mode.xpath:
            result = _getAnalyzeByXPath(result).getStringList(rule);
            break;
          case _Mode.regex:
            result = [rule];
            break;
          default:
            result = _getAnalyzeByJSoup(result).getStringList(rule);
        }
        
        if (sourceRule.replaceRegex.isNotEmpty) {
          if (result is List) {
            result = result.map((e) => _replaceRegex(e.toString(), sourceRule)).toList();
          } else {
            result = _replaceRegex(result?.toString() ?? "", sourceRule);
          }
        }
      }
    }
    
    if (result is List) return result.map((e) => e.toString()).toList();
    if (result == null) return [];
    final str = result.toString();
    return str.split('\n');
  }

  List<_SourceRule> splitSourceRule(String ruleStr) {
    final ruleList = <_SourceRule>[];
    // Simple split for now, Legado's JS_PATTERN logic is complex
    // Most rules are single or split by @js:
    if (ruleStr.contains('@js:')) {
      final parts = ruleStr.split('@js:');
      if (parts[0].isNotEmpty) ruleList.add(_SourceRule(parts[0]));
      ruleList.add(_SourceRule(parts[1], mode: _Mode.js));
    } else {
      ruleList.add(_SourceRule(ruleStr));
    }
    return ruleList;
  }

  String _replaceRegex(String result, _SourceRule rule) {
    if (rule.replaceRegex.isEmpty) return result;
    final regex = RegExp(rule.replaceRegex, multiLine: true, dotAll: true);
    if (rule.replaceFirst) {
      return result.replaceFirst(regex, rule.replacement);
    } else {
      return result.replaceAll(regex, rule.replacement);
    }
  }

  dynamic evalJS(String jsStr, dynamic result) {
    // TODO: Implement using flutter_js in Phase 3
    // For now, return a stub or some basic logic
    if (jsStr == "result") return result;
    return "JS_STUB: $jsStr";
  }

  void put(String key, String value) {
    ruleData?.putVariable(key, value);
  }

  String get(String key) {
    return ruleData?.getVariable(key) ?? "";
  }
}

enum _Mode { xpath, json, defaultMode, js, regex }

class _SourceRule {
  String rule;
  _Mode mode;
  String replaceRegex = "";
  String replacement = "";
  bool replaceFirst = false;
  Map<String, String> putMap = {};

  _SourceRule(this.rule, {this.mode = _Mode.defaultMode}) {
    if (mode == _Mode.defaultMode) {
      if (rule.startsWith('@Json:')) {
        mode = _Mode.json;
        rule = rule.substring(6);
      } else if (rule.startsWith('@XPath:')) {
        mode = _Mode.xpath;
        rule = rule.substring(7);
      } else if (rule.startsWith('/')) {
        mode = _Mode.xpath;
      } else if (rule.startsWith(r'$.') || rule.startsWith(r'$[')) {
        mode = _Mode.json;
      }
    }
    
    // Handle @get:{key} and {{js}}
    if (rule.contains('@get:{') || rule.contains('{{')) {
      if (mode == _Mode.defaultMode) {
        mode = _Mode.regex;
      }
    }
    
    // Handle ##regex##replacement
    if (rule.contains('##')) {
      final parts = rule.split('##');
      rule = parts[0];
      if (parts.length > 1) replaceRegex = parts[1];
      if (parts.length > 2) replacement = parts[2];
      if (parts.length > 3) replaceFirst = true;
    }
  }

  void makeUpRule(dynamic result, AnalyzeRule analyzer) {
    // Handle @get:{key}
    if (rule.contains('@get:{')) {
      final ra = RuleAnalyzer(rule);
      rule = ra.innerRuleRange('@get:{', '}', fr: (key) => analyzer.get(key));
    }
    // Handle {{js}}
    if (rule.contains('{{')) {
      final ra = RuleAnalyzer(rule);
      rule = ra.innerRuleRange('{{', '}}', fr: (js) => analyzer.evalJS(js, result)?.toString() ?? "");
    }
  }
}
