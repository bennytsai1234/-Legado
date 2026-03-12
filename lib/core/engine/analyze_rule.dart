import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:html_unescape/html_unescape.dart';
import 'parsers/analyze_by_css.dart';
import 'parsers/analyze_by_json_path.dart';
import 'parsers/analyze_by_xpath.dart';
import 'parsers/analyze_by_regex.dart';
import 'js/js_engine.dart';
import '../models/rule_data_interface.dart';

/// AnalyzeRule - 規則總控
/// 對應 Android: model/analyzeRule/AnalyzeRule.kt (32KB)
class AnalyzeRule {
  RuleDataInterface? ruleData;
  dynamic source; // BaseSource equivalent

  // 全域調試日誌流
  static StreamController<String>? debugLogController;

  void _log(String msg) {
    if (debugLogController != null && !debugLogController!.isClosed) {
      debugLogController!.add(msg);
    }
  }

  dynamic _content;
  String? _baseUrl;
  dynamic _chapter;
  String? _nextChapterUrl;
  int _page = 1;

  AnalyzeByXPath? _analyzeByXPath;
  AnalyzeByCss? _analyzeByJSoup;
  AnalyzeByJsonPath? _analyzeByJSonPath;
  JsEngine? _jsEngine;

  static final HtmlUnescape _htmlUnescape = HtmlUnescape();
  static final Map<String, RegExp> _regexCache = {};
  static final Map<String, List<SourceRule>> _stringRuleCache = {};
  static final Map<String, dynamic> _scriptCache =
      {}; // 模擬 Android CompiledScript

  AnalyzeRule({this.ruleData, this.source});

  AnalyzeRule setChapter(dynamic chapter) {
    _chapter = chapter;
    return this;
  }

  AnalyzeRule setNextChapterUrl(String? nextChapterUrl) {
    _nextChapterUrl = nextChapterUrl;
    return this;
  }

  AnalyzeRule setPage(int page) {
    _page = page;
    return this;
  }

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

  /// 獲取單個元素
  dynamic getElement(String ruleStr) {
    if (ruleStr.isEmpty) return null;

    _log("⇒ 執行 getElement: $ruleStr");
    var result = _content;
    final ruleList = _splitSourceRuleCacheString(ruleStr);

    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) break;

        sourceRule.makeUpRule(result, this);
        final rule = sourceRule.rule;
        _log("  ◇ 模式: ${sourceRule.mode.name}, 規則: $rule");

        switch (sourceRule.mode) {
          case Mode.regex:
            final elements = AnalyzeByRegex.getElement(
              result.toString(),
              rule.split('&&').where((s) => s.isNotEmpty).toList(),
            );
            result = elements?.join('');
            break;
          case Mode.json:
            result = _getAnalyzeByJSonPath(result).getObject(rule);
            break;
          case Mode.xpath:
            final elements = _getAnalyzeByXPath(result).getElements(rule);
            result = elements.isNotEmpty ? elements.first : null;
            break;
          case Mode.js:
            result = evalJS(rule, result);
            break;
          default:
            final elements = _getAnalyzeByJSoup(result).getElements(rule);
            result = elements.isNotEmpty ? elements.first : null;
        }

        if (result != null && sourceRule.replaceRegex.isNotEmpty) {
          _log(
            "  ◇ 正則替換: ${sourceRule.replaceRegex} -> ${sourceRule.replacement}",
          );
          result = _replaceRegex(result.toString(), sourceRule);
        }

        final preview = result?.toString() ?? "null";
        _log(
          "  └ 結果類型: ${result?.runtimeType}, 預覽: ${preview.length > 50 ? preview.substring(0, 50) : preview}",
        );
      }
    }
    return result;
  }

  /// 獲取列表
  List<dynamic> getElements(String ruleStr) {
    if (ruleStr.isEmpty) return [];

    _log("⇒ 執行 getElements: $ruleStr");
    var result = _content;
    final ruleList = _splitSourceRuleCacheString(ruleStr);

    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) break;

        sourceRule.makeUpRule(result, this);
        final rule = sourceRule.rule;
        _log("  ◇ 模式: ${sourceRule.mode.name}, 規則: $rule");

        switch (sourceRule.mode) {
          case Mode.regex:
            result = AnalyzeByRegex.getElements(
              result.toString(),
              rule.split('&&').where((s) => s.isNotEmpty).toList(),
            );
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

        if (result != null && sourceRule.replaceRegex.isNotEmpty) {
          _log("  ◇ 正則替換列表元素: ${sourceRule.replaceRegex}");
          if (result is List) {
            result =
                result
                    .map((e) => _replaceRegex(e.toString(), sourceRule))
                    .toList();
          } else {
            result = _replaceRegex(result.toString(), sourceRule);
          }
        }
        _log(
          "  └ 列表長度: ${result is List ? result.length : (result == null ? 0 : 1)}",
        );
      }
    }

    if (result is List) return result;
    if (result == null) return [];
    return [result];
  }

  /// 獲取單個字串
  String getString(String ruleStr, {bool isUrl = false, bool unescape = true}) {
    if (ruleStr.isEmpty) return "";

    _log("⇒ 執行 getString: $ruleStr");
    final ruleList = _splitSourceRuleCacheString(ruleStr);
    var result = _content;

    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) break;

        sourceRule.makeUpRule(result, this);
        final rule = sourceRule.rule;
        _log("  ◇ 模式: ${sourceRule.mode.name}, 規則: $rule");

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
          _log("  ◇ 正則替換: ${sourceRule.replaceRegex}");
          result = _replaceRegex(result.toString(), sourceRule);
        }

        final preview = result?.toString() ?? "null";
        _log(
          "  └ 字串預覽: ${preview.length > 50 ? preview.substring(0, 50) : preview}",
        );
      }
    }

    var str = result?.toString() ?? "";

    if (unescape && str.contains('&')) {
      str = _htmlUnescape.convert(str);
    }

    if (isUrl && str.isEmpty) return _baseUrl ?? "";
    return str;
  }

  /// 獲取字串列表
  List<String> getStringList(String ruleStr, {bool isUrl = false}) {
    if (ruleStr.isEmpty) return [];

    final ruleList = _splitSourceRuleCacheString(ruleStr);
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
            result = [
              rule,
            ]; // Regex mode in getStringList usually returns the rule itself after makeup
            break;
          default:
            result = _getAnalyzeByJSoup(result).getStringList(rule);
        }

        if (sourceRule.replaceRegex.isNotEmpty) {
          if (result is List) {
            result =
                result
                    .map((e) => _replaceRegex(e.toString(), sourceRule))
                    .toList();
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

  List<SourceRule> _splitSourceRuleCacheString(String ruleStr) {
    if (ruleStr.isEmpty) return [];
    if (_stringRuleCache.containsKey(ruleStr)) {
      return _stringRuleCache[ruleStr]!;
    }
    final ruleList = splitSourceRule(ruleStr);
    if (_stringRuleCache.length > 50) _stringRuleCache.clear();
    _stringRuleCache[ruleStr] = ruleList;
    return ruleList;
  }

  List<SourceRule> splitSourceRule(String ruleStr) {
    final ruleList = <SourceRule>[];

    // Legado JS_PATTERN: @js: 或 <js>...</js>
    final jsPattern = RegExp(
      r'@js:|(<js>([\w\W]*?)</js>)',
      caseSensitive: false,
    );

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

    RegExp? regex;
    if (_regexCache.containsKey(rule.replaceRegex)) {
      regex = _regexCache[rule.replaceRegex];
    } else {
      try {
        regex = RegExp(rule.replaceRegex, multiLine: true, dotAll: true);
        if (_regexCache.length > 100) _regexCache.clear();
        _regexCache[rule.replaceRegex] = regex;
      } catch (e) {
        return result; // Invalid regex
      }
    }

    if (regex == null) return result;

    if (rule.replaceFirst) {
      /* ##match##replace### 獲取第一個匹配到的結果並進行替換 */
      return result.replaceFirstMapped(regex, (match) {
        var res = rule.replacement;
        for (int i = 0; i <= match.groupCount; i++) {
          res = res.replaceAll('\$$i', match.group(i) ?? "");
        }
        return res;
      });
    } else {
      /* ##match##replace 替換所有 */
      return result.replaceAllMapped(regex, (match) {
        var res = rule.replacement;
        for (int i = 0; i <= match.groupCount; i++) {
          res = res.replaceAll('\$$i', match.group(i) ?? "");
        }
        return res;
      });
    }
  }

  dynamic evalJS(String jsStr, dynamic result) {
    _jsEngine ??= JsEngine(source: source);

    if (_scriptCache.containsKey(jsStr) && result == null) {
      return _scriptCache[jsStr];
    }

    dynamic sourceMap;
    try {
      sourceMap = source?.toJson();
    } catch (_) {
      sourceMap = source;
    }

    dynamic chapterMap;
    try {
      chapterMap = _chapter?.toJson();
    } catch (_) {
      chapterMap = _chapter;
    }

    final context = {
      'java': this,
      'result': result,
      'baseUrl': _baseUrl,
      'source': sourceMap,
      'chapter': chapterMap,
      'title': _chapter?.title,
      'nextChapterUrl': _nextChapterUrl,
      'page': _page,
      'src': _content,
    };

    final evalResult = _jsEngine!.evaluate(jsStr, context: context);
    if (result == null && _scriptCache.length < 100) {
      _scriptCache[jsStr] = evalResult;
    }
    return evalResult;
  }

  void reGetBook() {
    debugPrint("AnalyzeRule: reGetBook called");
  }

  void refreshTocUrl() {
    debugPrint("AnalyzeRule: refreshTocUrl called");
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

  List<String> ruleParam = [];
  List<int> ruleType = [];

  static const int getRuleType = -2;
  static const int jsRuleType = -1;
  static const int defaultRuleType = 0;

  SourceRule(this.rule, {this.mode = Mode.defaultMode}) {
    // 1. 初始化 Mode (高度還原 Android init)
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

    // 2. 分離 @put 規則
    final putPattern = RegExp(r'@put:(\{.*?\})', caseSensitive: false);
    var vRuleStr = rule;
    final putMatches = putPattern.allMatches(rule);
    for (final putMatch in putMatches) {
      vRuleStr = vRuleStr.replaceFirst(putMatch.group(0)!, "");
      try {
        final jsonStr = putMatch.group(1)!;
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        map.forEach((k, v) => putMap[k] = v.toString());
      } catch (_) {}
    }
    rule = vRuleStr;

    // 3. 拆分 @get, {{ }} (高度還原 Android init 核心)
    final evalPattern = RegExp(
      r'@get:\{[^}]+?\}|\{\{[\w\W]*?\}\}',
      caseSensitive: false,
    );
    int start = 0;
    final evalMatches = evalPattern.allMatches(rule);

    for (final match in evalMatches) {
      if (match.start > start) {
        _splitRegex(rule.substring(start, match.start));
      }
      final tmp = match.group(0)!;
      if (tmp.toLowerCase().startsWith('@get:')) {
        ruleType.add(getRuleType);
        ruleParam.add(tmp.substring(6, tmp.length - 1));
      } else if (tmp.startsWith('{{')) {
        ruleType.add(jsRuleType);
        ruleParam.add(tmp.substring(2, tmp.length - 2));
      }
      start = match.end;
    }
    if (rule.length > start) {
      _splitRegex(rule.substring(start));
    }
  }

  void _splitRegex(String ruleStr) {
    int start = 0;
    final regexPattern = RegExp(r'\$\d{1,2}');
    final matches = regexPattern.allMatches(ruleStr);

    if (matches.isNotEmpty && mode != Mode.js) {
      mode = Mode.regex;
    }

    for (final match in matches) {
      if (match.start > start) {
        ruleType.add(defaultRuleType);
        ruleParam.add(ruleStr.substring(start, match.start));
      }
      ruleType.add(int.parse(match.group(0)!.substring(1)));
      ruleParam.add(match.group(0)!);
      start = match.end;
    }
    if (ruleStr.length > start) {
      ruleType.add(defaultRuleType);
      ruleParam.add(ruleStr.substring(start));
    }
  }

  void makeUpRule(dynamic result, AnalyzeRule analyzer) {
    // 1. 執行 @put
    putMap.forEach((key, value) {
      analyzer.put(key, analyzer.getString(value));
    });

    // 2. 組合動態參數 (高度還原 Android makeUpRule)
    if (ruleParam.isNotEmpty) {
      final infoVal = StringBuffer();
      for (int i = 0; i < ruleParam.length; i++) {
        final type = ruleType[i];
        if (type > defaultRuleType) {
          if (result is List && result.length > type) {
            infoVal.write(result[type]?.toString() ?? "");
          } else {
            infoVal.write(ruleParam[i]);
          }
        } else if (type == jsRuleType) {
          infoVal.write(
            analyzer.evalJS(ruleParam[i], result)?.toString() ?? "",
          );
        } else if (type == getRuleType) {
          infoVal.write(analyzer.get(ruleParam[i]));
        } else {
          infoVal.write(ruleParam[i]);
        }
      }
      rule = infoVal.toString();
    }

    // 3. 分離正則替換部分 ##regex##replacement###
    final ruleStrArray = rule.split('##');
    rule = ruleStrArray[0].trim();
    if (ruleStrArray.length > 1) replaceRegex = ruleStrArray[1];
    if (ruleStrArray.length > 2) replacement = ruleStrArray[2];
    if (ruleStrArray.length > 3) replaceFirst = true;
  }
}
