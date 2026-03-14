import 'analyze_rule_base.dart';
import 'analyze_rule_support.dart';
import '../parsers/analyze_by_regex.dart';

/// AnalyzeRule 的核心解析擴展
extension AnalyzeRuleCore on AnalyzeRuleBase {
  /// 獲取單個元素
  dynamic getElement(String ruleStr) {
    if (ruleStr.isEmpty) return null;

    log("⇒ 執行 getElement: $ruleStr");
    var result = content;
    final ruleList = splitSourceRuleCacheString(ruleStr);

    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) break;

        sourceRule.makeUpRule(result, this as dynamic);
        final rule = sourceRule.rule;
        log("  ◇ 模式: ${sourceRule.mode.name}, 規則: $rule");

        dynamic tempResult;
        switch (sourceRule.mode) {
          case Mode.regex:
            final elements = AnalyzeByRegex.getElement(
              result.toString(),
              rule.split('&&').where((s) => s.isNotEmpty).toList(),
            );
            tempResult = elements?.join('');
            break;
          case Mode.json:
            tempResult = sourceRule.getAnalyzeByJSonPath(this, result).getObject(rule);
            break;
          case Mode.xpath:
            final elements = sourceRule.getAnalyzeByXPath(this, result).getElements(rule);
            tempResult = elements.isNotEmpty ? elements.first : null;
            break;
          case Mode.js:
            tempResult = (this as dynamic).evalJS(rule, result);
            break;
          default:
            final elements = sourceRule.getAnalyzeByJSoup(this, result).getElements(rule);
            tempResult = elements.isNotEmpty ? elements.first : null;
        }

        if (sourceRule.isDynamic && (tempResult == null || tempResult.toString().isEmpty)) {
          result = rule;
        } else {
          result = tempResult;
        }

        if (result != null && sourceRule.replaceRegex.isNotEmpty) {
          log("  ◇ 正則替換: ${sourceRule.replaceRegex} -> ${sourceRule.replacement}");
          result = replaceRegexLogic(result.toString(), sourceRule);
        }

        final preview = result?.toString() ?? "null";
        log("  └ 結果類型: ${result?.runtimeType}, 預覽: ${preview.length > 500 ? preview.substring(0, 500) : preview}");
      }
    }
    return result;
  }

  /// 獲取列表
  List<dynamic> getElements(String ruleStr) {
    if (ruleStr.isEmpty) return [];

    log("⇒ 執行 getElements: $ruleStr");
    var result = content;
    final ruleList = splitSourceRuleCacheString(ruleStr);

    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) break;

        sourceRule.makeUpRule(result, this as dynamic);
        final rule = sourceRule.rule;
        log("  ◇ 模式: ${sourceRule.mode.name}, 規則: $rule");

        dynamic tempResult;
        switch (sourceRule.mode) {
          case Mode.regex:
            tempResult = AnalyzeByRegex.getElements(
              result.toString(),
              rule.split('&&').where((s) => s.isNotEmpty).toList(),
            );
            break;
          case Mode.json:
            tempResult = sourceRule.getAnalyzeByJSonPath(this, result).getElements(rule);
            break;
          case Mode.xpath:
            tempResult = sourceRule.getAnalyzeByXPath(this, result).getElements(rule);
            break;
          case Mode.js:
            tempResult = (this as dynamic).evalJS(rule, result);
            break;
          default:
            tempResult = sourceRule.getAnalyzeByJSoup(this, result).getElements(rule);
        }

        if (sourceRule.isDynamic &&
            (tempResult == null ||
                (tempResult is List && tempResult.isEmpty) ||
                (tempResult is String && tempResult.isEmpty))) {
          result = rule;
        } else {
          result = tempResult;
        }

        if (result != null && sourceRule.replaceRegex.isNotEmpty) {
          log("  ◇ 正則替換列表元素: ${sourceRule.replaceRegex}");
          if (result is List) {
            result = result.map((e) => replaceRegexLogic(e.toString(), sourceRule)).toList();
          } else {
            result = replaceRegexLogic(result.toString(), sourceRule);
          }
        }
        log("  └ 列表長度: ${result is List ? result.length : (result == null ? 0 : 1)}");
      }
    }

    if (result is List) return result;
    if (result == null) return [];
    return [result];
  }

  /// 獲取單個字串
  String getString(String ruleStr, {bool isUrl = false, bool unescape = true}) {
    if (ruleStr.isEmpty) return "";

    log("⇒ 執行 getString: $ruleStr");
    final ruleList = splitSourceRuleCacheString(ruleStr);
    var result = content;

    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) break;

        sourceRule.makeUpRule(result, this as dynamic);
        final rule = sourceRule.rule;
        log("  ◇ 模式: ${sourceRule.mode.name}, 規則: $rule");

        dynamic tempResult;
        if (rule.isNotEmpty || sourceRule.replaceRegex.isEmpty) {
          switch (sourceRule.mode) {
            case Mode.js:
              tempResult = (this as dynamic).evalJS(rule, result);
              break;
            case Mode.json:
              tempResult = sourceRule.getAnalyzeByJSonPath(this, result).getString(rule);
              break;
            case Mode.xpath:
              tempResult = sourceRule.getAnalyzeByXPath(this, result).getString(rule);
              break;
            case Mode.regex:
              if (sourceRule.replaceRegex.isEmpty) {
                tempResult = rule;
              } else {
                tempResult = AnalyzeByRegex.getString(result.toString(), rule);
              }
              break;
            default:
              tempResult = sourceRule.getAnalyzeByJSoup(this, result).getString(rule);
          }
        }

        if (sourceRule.isDynamic && (tempResult == null || tempResult.toString().isEmpty)) {
          result = rule;
        } else {
          result = tempResult;
        }

        if (result != null && sourceRule.replaceRegex.isNotEmpty) {
          log("  ◇ 正則替換: ${sourceRule.replaceRegex}");
          result = replaceRegexLogic(result.toString(), sourceRule);
        }

        final preview = result?.toString() ?? "null";
        log("  └ 字串預覽: ${preview.length > 500 ? preview.substring(0, 500) : preview}");
      }
    }

    var str = result?.toString() ?? "";
    if (unescape && str.contains('&')) {
      str = AnalyzeRuleBase.htmlUnescape.convert(str);
    }
    if (isUrl && str.isEmpty) return baseUrl ?? "";
    return str;
  }

  /// 獲取字串列表
  List<String> getStringList(String ruleStr, {bool isUrl = false}) {
    if (ruleStr.isEmpty) return [];
    log("⇒ 執行 getStringList: $ruleStr");

    final ruleList = splitSourceRuleCacheString(ruleStr);
    var result = content;

    if (result != null && ruleList.isNotEmpty) {
      for (final sourceRule in ruleList) {
        if (result == null) break;

        sourceRule.makeUpRule(result, this as dynamic);
        final rule = sourceRule.rule;
        log("  ◇ 模式: ${sourceRule.mode.name}, 規則: $rule");

        switch (sourceRule.mode) {
          case Mode.js:
            result = (this as dynamic).evalJS(rule, result);
            break;
          case Mode.json:
            result = sourceRule.getAnalyzeByJSonPath(this, result).getStringList(rule);
            break;
          case Mode.xpath:
            result = sourceRule.getAnalyzeByXPath(this, result).getStringList(rule);
            break;
          case Mode.regex:
            result = [rule];
            break;
          default:
            result = sourceRule.getAnalyzeByJSoup(this, result).getStringList(rule);
        }

        if (sourceRule.replaceRegex.isNotEmpty) {
          log("  ◇ 正則替換列表: ${sourceRule.replaceRegex}");
          if (result is List) {
            result = result.map((e) => replaceRegexLogic(e.toString(), sourceRule)).toList();
          } else {
            result = replaceRegexLogic(result?.toString() ?? "", sourceRule);
          }
        }
      }
    }

    if (result is List) return result.map((e) => e.toString()).toSet().toList();
    if (result == null) return [];
    final str = result.toString();
    return str.split('\n').where((s) => s.isNotEmpty).toSet().toList();
  }

  List<SourceRule> splitSourceRuleCacheString(String ruleStr) {
    if (ruleStr.isEmpty) return [];
    if (AnalyzeRuleBase.stringRuleCache.containsKey(ruleStr)) {
      return AnalyzeRuleBase.stringRuleCache[ruleStr]!;
    }
    final ruleList = splitSourceRule(ruleStr);
    if (AnalyzeRuleBase.stringRuleCache.length > 50) AnalyzeRuleBase.stringRuleCache.clear();
    AnalyzeRuleBase.stringRuleCache[ruleStr] = ruleList;
    return ruleList;
  }

  List<SourceRule> splitSourceRule(String ruleStr) {
    final ruleList = <SourceRule>[];
    final jsPattern = RegExp(r'@js:|(<js>([\w\W]*?)</js>)', caseSensitive: false);
    var start = 0;
    final matches = jsPattern.allMatches(ruleStr);

    for (final match in matches) {
      if (match.start > start) {
        final tmp = ruleStr.substring(start, match.start).trim();
        if (tmp.isNotEmpty) ruleList.add(SourceRule(tmp));
      }
      if (match.group(0)!.toLowerCase() == '@js:') {
        final jsCode = ruleStr.substring(match.end).trim();
        ruleList.add(SourceRule(jsCode, mode: Mode.js));
        return ruleList;
      } else {
        final jsCode = match.group(2)!.trim();
        ruleList.add(SourceRule(jsCode, mode: Mode.js));
      }
      start = match.end;
    }
    if (ruleStr.length > start) {
      final tmp = ruleStr.substring(start).trim();
      if (tmp.isNotEmpty) ruleList.add(SourceRule(tmp));
    }
    return ruleList;
  }

  String replaceRegexLogic(String result, SourceRule rule) {
    if (rule.replaceRegex.isEmpty) return result;
    RegExp? regex;
    if (AnalyzeRuleBase.regexCache.containsKey(rule.replaceRegex)) {
      regex = AnalyzeRuleBase.regexCache[rule.replaceRegex];
    } else {
      try {
        regex = RegExp(rule.replaceRegex, multiLine: true, dotAll: true);
        if (AnalyzeRuleBase.regexCache.length > 100) AnalyzeRuleBase.regexCache.clear();
        AnalyzeRuleBase.regexCache[rule.replaceRegex] = regex;
      } catch (e) { return result; }
    }
    if (regex == null) return result;
    if (rule.replaceFirst) {
      return result.replaceFirstMapped(regex, (match) {
        var res = rule.replacement;
        for (int i = 0; i <= match.groupCount; i++) { res = res.replaceAll('\$$i', match.group(i) ?? ""); }
        return res;
      });
    } else {
      return result.replaceAllMapped(regex, (match) {
        var res = rule.replacement;
        for (int i = 0; i <= match.groupCount; i++) { res = res.replaceAll('\$$i', match.group(i) ?? ""); }
        return res;
      });
    }
  }
}
