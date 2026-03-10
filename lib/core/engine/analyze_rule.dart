import 'dart:convert';
import 'package:html/dom.dart';
import 'parsers/analyze_by_css.dart';
import 'parsers/analyze_by_json_path.dart';
import 'parsers/analyze_by_xpath.dart';
import 'parsers/analyze_by_regex.dart';
import 'rule_analyzer.dart';
import 'js/js_engine.dart';
import '../models/rule_data_interface.dart';

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
  JsEngine? _jsEngine;

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
        
        sourceRule.makeUpRule(result, this);
        final rule = sourceRule.rule;
        
        switch (sourceRule.mode) {
          case Mode.regex:
            result = AnalyzeByRegex.getElements(result.toString(), rule.split('&&').where((s) => s.isNotEmpty).toList());
            break;
          case Mode.json:
            result = _getAnalyzeByJSonPath(result).getElements(rule);
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
              if (sourceRule.replaceRegex.isEmpty) {
                result = rule;
              } else {
                result = AnalyzeByRegex.getString(result.toString(), rule);
              }
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
            result = [rule]; // Regex mode in getStringList usually returns the rule itself after makeup
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
    
    if (result is List) {
      return result.map((e) => e.toString()).toSet().toList();
    }
    if (result == null) return [];
    final str = result.toString();
    return str.split('\n').where((s) => s.isNotEmpty).toSet().toList();
  }

  List<SourceRule> splitSourceRule(String ruleStr) {
    final ruleList = <SourceRule>[];
    
    // Legado JS_PATTERN: @js: 或 <js>...</js>
    final jsPattern = RegExp(r'@js:|(<js>([\w\W]*?)</js>)', caseSensitive: false);
    
    var start = 0;
    final matches = jsPattern.allMatches(ruleStr);
    
    for (final match in matches) {
      if (match.start > start) {
        final tmp = ruleStr.substring(start, match.start).trim();
        if (tmp.isNotEmpty) {
          ruleList.add(SourceRule(tmp));
        }
      }
      
      if (match.group(0)!.toLowerCase() == '@js:') {
        final jsCode = ruleStr.substring(match.end).trim();
        ruleList.add(SourceRule(jsCode, mode: Mode.js));
        return ruleList; // @js: matches everything to the end
      } else {
        final jsCode = match.group(2)!.trim();
        ruleList.add(SourceRule(jsCode, mode: Mode.js));
      }
      start = match.end;
    }

    if (ruleStr.length > start) {
      final tmp = ruleStr.substring(start).trim();
      if (tmp.isNotEmpty) {
        ruleList.add(SourceRule(tmp));
      }
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
    _jsEngine ??= JsEngine();
    
    final context = {
      'result': result,
      'baseUrl': _baseUrl,
      'java': this,
    };
    
    return _jsEngine!.evaluate(jsStr, context: context);
  }

  void put(String key, String? value) {
    ruleData?.putVariable(key, value);
  }

  String get(String key) {
    return ruleData?.getVariable(key) ?? "";
  }
  
  void dispose() {
    _jsEngine?.dispose();
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
      } else if (rule.startsWith('/') && !rule.startsWith('//')) {
        mode = Mode.xpath;
      } else if (rule.startsWith(r'$.') || rule.startsWith(r'$[')) {
        mode = Mode.json;
      }
    }
    
    // Handle @put
    final putPattern = RegExp(r'@put:(\{.*?\})', caseSensitive: false);
    final putMatch = putPattern.firstMatch(rule);
    if (putMatch != null) {
      try {
        final jsonStr = putMatch.group(1)!;
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        map.forEach((k, v) {
          putMap[k] = v.toString();
        });
        rule = rule.replaceFirst(putMatch.group(0)!, "");
      } catch (e) {
        // Ignore invalid JSON
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
    // Apply @put
    putMap.forEach((key, value) {
      analyzer.put(key, analyzer.getString(value));
    });

    // Handle nested rules like {$.id} or {$.name}
    if (rule.contains(r'{$.') || rule.contains(r'{$[')) {
      final ra = RuleAnalyzer(rule);
      rule = ra.innerRuleRange('{', '}', fr: (nestedRule) {
        if (nestedRule.startsWith(r'$.') || nestedRule.startsWith(r'$[')) {
          return analyzer.getString(nestedRule);
        }
        return null; // Return null to skip if not a rule
      });
    }

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
