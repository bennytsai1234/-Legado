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

  AnalyzeByXPath? _analyzeByXPath;
  AnalyzeByCss? _analyzeByJSoup;
  AnalyzeByJsonPath? _analyzeByJSonPath;

  AnalyzeRule({this.ruleData, this.source});

  AnalyzeRule setContent(dynamic content, {String? baseUrl}) {
    if (content == null) throw ArgumentError("Content cannot be null");
    _content = content;
    _baseUrl = baseUrl;
    _analyzeByXPath = null;
    _analyzeByJSoup = null;
    _analyzeByJSonPath = null;
    return this;
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
          case Mode.regex:
            result = AnalyzeByRegex.getElements(result.toString(), rule.split('&&').where((s) => s.isNotEmpty).toList());
            break;
          case Mode.json:
            result = _getAnalyzeByJSonPath(result).getList(rule);
            break;
          case Mode.xpath:
            result = _getAnalyzeByXPath(result).getElements(rule);
            break;
          case Mode.js:
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
            case Mode.js:
              result = evalJS(rule, result);
              break;
            case Mode.json:
              result = _getAnalyzeByJSonPath(result).getString(rule);
              break;
            case Mode.xpath:
              result = _getAnalyzeByXPath(result).getString(rule);
              break;
            case Mode.regex:
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
    
    if (isUrl && str.isEmpty) return _baseUrl ?? "";
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
          case Mode.js:
            result = evalJS(rule, result);
            break;
          case Mode.json:
            result = _getAnalyzeByJSonPath(result).getStringList(rule);
            break;
          case Mode.xpath:
            result = _getAnalyzeByXPath(result).getStringList(rule);
            break;
          case Mode.regex:
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

  List<SourceRule> splitSourceRule(String ruleStr) {
    final ruleList = <SourceRule>[];
    // Simple split for now
    if (ruleStr.contains('@js:')) {
      final parts = ruleStr.split('@js:');
      if (parts[0].isNotEmpty) ruleList.add(SourceRule(parts[0]));
      ruleList.add(SourceRule(parts[1], mode: Mode.js));
    } else {
      ruleList.add(SourceRule(ruleStr));
    }
    return ruleList;
  }

  String _replaceRegex(String result, SourceRule rule) {
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

enum Mode { xpath, json, defaultMode, js, regex }

class SourceRule {
  String rule;
  Mode mode;
  String replaceRegex = "";
  String replacement = "";
  bool replaceFirst = false;
  Map<String, String> putMap = {};

  SourceRule(this.rule, {this.mode = Mode.defaultMode}) {
    if (mode == Mode.defaultMode) {
      if (rule.startsWith('@Json:')) {
        mode = Mode.json;
        rule = rule.substring(6);
      } else if (rule.startsWith('@XPath:')) {
        mode = Mode.xpath;
        rule = rule.substring(7);
      } else if (rule.startsWith('/')) {
        mode = Mode.xpath;
      } else if (rule.startsWith(r'$.') || rule.startsWith(r'$[')) {
        mode = Mode.json;
      }
    }
    
    // Handle @get:{key} and {{js}}
    if (rule.contains('@get:{') || rule.contains('{{')) {
      if (mode == Mode.defaultMode) {
        mode = Mode.regex;
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
