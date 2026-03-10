import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import '../rule_analyzer.dart';

/// AnalyzeByCss - CSS 選擇器解析器
/// 對應 Android: model/analyzeRule/AnalyzeByJSoup.kt (18KB)
///
/// 使用 Dart `html` 套件
class AnalyzeByCss {
  late Element element;

  AnalyzeByCss(dynamic doc) {
    if (doc is Element) {
      element = doc;
    } else if (doc is String) {
      final document = html_parser.parse(doc);
      element = document.documentElement!;
    } else {
      element = html_parser.parse(doc.toString()).documentElement!;
    }
  }

  /// 獲取列表
  List<Element> getElements(String rule) {
    if (rule.isEmpty) return [];

    final sourceRule = _SourceRule(rule);
    final ruleAnalyzes = RuleAnalyzer(sourceRule.elementsRule);
    final ruleStrS = ruleAnalyzes.splitRule(['&&', '||', '%%']);

    final elementsList = <List<Element>>[];
    if (sourceRule.isCss) {
      for (String ruleStr in ruleStrS) {
        ruleStr = ruleStr.trim();
        if (ruleStr.isEmpty) continue;
        final tempS = element.querySelectorAll(ruleStr);
        elementsList.add(tempS);
        if (tempS.isNotEmpty && ruleAnalyzes.elementsType == '||') {
          break;
        }
      }
    } else {
      for (String ruleStr in ruleStrS) {
        ruleStr = ruleStr.trim();
        if (ruleStr.isEmpty) continue;
        final rsRule = RuleAnalyzer(ruleStr);
        rsRule.trim();
        final rs = rsRule.splitRule(['@']);

        List<Element> el;
        if (rs.length > 1) {
          el = [element];
          for (String rl in rs) {
            rl = rl.trim();
            if (rl.isEmpty) continue;
            final es = <Element>[];
            for (final et in el) {
              es.addAll(_getElementsSingle(et, rl));
            }
            el = es;
          }
        } else {
          el = _getElementsSingle(element, ruleStr);
        }

        elementsList.add(el);
        if (el.isNotEmpty && ruleAnalyzes.elementsType == '||') {
          break;
        }
      }
    }

    if (elementsList.isEmpty) {
      return [];
    }

    final result = <Element>[];
    if (ruleAnalyzes.elementsType == '%%') {
      final firstListSize = elementsList[0].length;
      for (int i = 0; i < firstListSize; i++) {
        for (final es in elementsList) {
          if (i < es.length) {
            result.add(es[i]);
          }
        }
      }
    } else {
      for (final es in elementsList) {
        result.addAll(es);
      }
    }
    return result;
  }

  /// 獲取所有內容列表
  List<String> getStringList(String ruleStr) {
    if (ruleStr.isEmpty) return [];

    final sourceRule = _SourceRule(ruleStr);
    if (sourceRule.elementsRule.isEmpty) {
      // In Kotlin: element.data() ?: ""
      // But usually we want text
      return [element.text];
    }

    final ruleAnalyzes = RuleAnalyzer(sourceRule.elementsRule);
    final ruleStrS = ruleAnalyzes.splitRule(['&&', '||', '%%']);

    final results = <List<String>>[];
    for (String ruleStrX in ruleStrS) {
      ruleStrX = ruleStrX.trim();
      if (ruleStrX.isEmpty) continue;

      List<String>? temp;
      if (sourceRule.isCss) {
        final lastIndex = ruleStrX.lastIndexOf('@');
        if (lastIndex != -1) {
          final cssSelector = ruleStrX.substring(0, lastIndex);
          final attr = ruleStrX.substring(lastIndex + 1);
          temp = _getResultLast(element.querySelectorAll(cssSelector), attr);
        } else {
          // If no @, default to text?
          temp = _getResultLast(element.querySelectorAll(ruleStrX), 'text');
        }
      } else {
        temp = _getResultList(ruleStrX);
      }

      if (temp != null && temp.isNotEmpty) {
        results.add(temp);
        if (ruleAnalyzes.elementsType == '||') break;
      }
    }

    if (results.isEmpty) return [];

    final textS = <String>[];
    if (ruleAnalyzes.elementsType == '%%') {
      final firstListSize = results[0].length;
      for (int i = 0; i < firstListSize; i++) {
        for (final temp in results) {
          if (i < temp.length) {
            textS.add(temp[i]);
          }
        }
      }
    } else {
      for (final temp in results) {
        textS.addAll(temp);
      }
    }
    return textS;
  }

  String? getString(String ruleStr) {
    if (ruleStr.isEmpty) return null;
    final list = getStringList(ruleStr);
    if (list.isEmpty) return null;
    if (list.length == 1) return list.first;
    return list.join('\n');
  }

  List<String>? _getResultList(String ruleStr) {
    if (ruleStr.isEmpty) return null;

    var elements = [element];
    final rule = RuleAnalyzer(ruleStr);
    rule.trim();
    final rules = rule.splitRule(['@']);

    final last = rules.length - 1;
    for (int i = 0; i < last; i++) {
      final es = <Element>[];
      for (final elt in elements) {
        es.addAll(_getElementsSingle(elt, rules[i]));
      }
      elements = es;
    }

    if (elements.isEmpty) return null;
    return _getResultLast(elements, rules[last]);
  }

  List<String> _getResultLast(List<Element> elements, String lastRule) {
    final textS = <String>[];
    switch (lastRule) {
      case 'text':
        for (final el in elements) {
          final t = el.text.trim();
          if (t.isNotEmpty) textS.add(t);
        }
        break;
      case 'textNodes':
        for (final el in elements) {
          final nodes = el.nodes
              .where((n) => n.nodeType == Node.TEXT_NODE)
              .map((n) => n.text?.trim() ?? "")
              .where((t) => t.isNotEmpty)
              .join('\n');
          if (nodes.isNotEmpty) textS.add(nodes);
        }
        break;
      case 'ownText':
        for (final el in elements) {
          final t = el.nodes
              .where((n) => n.nodeType == Node.TEXT_NODE)
              .map((n) => n.text?.trim() ?? "")
              .where((t) => t.isNotEmpty)
              .join(' ');
          if (t.isNotEmpty) textS.add(t);
        }
        break;
      case 'html':
        for (final el in elements) {
          // Remove script and style as in Kotlin
          el.querySelectorAll('script').forEach((s) => s.remove());
          el.querySelectorAll('style').forEach((s) => s.remove());
          final h = el.outerHtml;
          if (h.isNotEmpty) textS.add(h);
        }
        break;
      case 'all':
        for (final el in elements) {
          textS.add(el.outerHtml);
        }
        break;
      default:
        for (final el in elements) {
          final attr = el.attributes[lastRule];
          if (attr != null && attr.trim().isNotEmpty) {
            textS.add(attr.trim());
          }
        }
    }
    return textS;
  }

  List<Element> _getElementsSingle(Element temp, String rule) {
    final single = _ElementsSingle();
    return single.getElementsSingle(temp, rule);
  }
}

class _SourceRule {
  bool isCss = false;
  late String elementsRule;

  _SourceRule(String ruleStr) {
    if (ruleStr.toUpperCase().startsWith('@CSS:')) {
      isCss = true;
      elementsRule = ruleStr.substring(5).trim();
    } else {
      elementsRule = ruleStr;
    }
  }
}

class _ElementsSingle {
  String split = '.';
  String beforeRule = '';
  final List<int> indexDefault = [];
  final List<dynamic> indexes = [];

  List<Element> getElementsSingle(Element temp, String rule) {
    _findIndexSet(rule);

    List<Element> elements;
    if (beforeRule.isEmpty) {
      elements = temp.children;
    } else {
      final rules = beforeRule.split('.');
      if (rules[0] == 'children') {
        elements = temp.children;
      } else if (rules[0] == 'class' && rules.length > 1) {
        elements = temp.getElementsByClassName(rules[1]);
      } else if (rules[0] == 'tag' && rules.length > 1) {
        elements = temp.getElementsByTagName(rules[1]);
      } else if (rules[0] == 'id' && rules.length > 1) {
        final el = temp.querySelector('#${rules[1]}');
        elements = el != null ? [el] : [];
      } else if (rules[0] == 'text' && rules.length > 1) {
        // Find elements containing own text
        elements = temp.querySelectorAll('*').where((el) {
           return el.nodes.any((n) => n.nodeType == Node.TEXT_NODE && n.text!.contains(rules[1]));
        }).toList();
      } else {
        elements = temp.querySelectorAll(beforeRule);
      }
    }

    final len = elements.length;
    if (len == 0) return [];

    final lastIndexes = indexDefault.isNotEmpty ? indexDefault.length - 1 : indexes.length - 1;
    final indexSet = <int>{};

    if (indexes.isEmpty) {
      for (int i = lastIndexes; i >= 0; i--) {
        int it = indexDefault[i];
        if (it >= 0 && it < len) {
          indexSet.add(it);
        } else if (it < 0 && len >= -it) {
          indexSet.add(it + len);
        }
      }
    } else {
      for (int i = lastIndexes; i >= 0; i--) {
        final idx = indexes[i];
        if (idx is _Triple) {
          int start = idx.first ?? 0;
          if (start < 0) start += len;
          int end = idx.second ?? (len - 1);
          if (end < 0) end += len;

          if ((start < 0 && end < 0) || (start >= len && end >= len)) continue;

          start = start.clamp(0, len - 1);
          end = end.clamp(0, len - 1);

          int step = idx.third;
          if (step == 0) step = 1;
          if (step < 0 && -step < len) step += len;
          if (step <= 0) step = 1;

          if (start <= end) {
            for (int j = start; j <= end; j += step) {
              indexSet.add(j);
            }
          } else {
            for (int j = start; j >= end; j -= step) {
              indexSet.add(j);
            }
          }
        } else if (idx is int) {
          int it = idx;
          if (it >= 0 && it < len) {
            indexSet.add(it);
          } else if (it < 0 && len >= -it) {
            indexSet.add(it + len);
          }
        }
      }
    }

    if (split == '!' || split == '.') {
      final result = <Element>[];
      for (final idx in indexSet) {
        result.add(elements[idx]);
      }
      return result;
    } else {
      return elements;
    }
  }

  void _findIndexSet(String rule) {
    String rus = rule.trim();
    int len = rus.length;
    bool curMinus = false;
    final curList = <int?>[];
    String l = '';

    bool head = rus.endsWith(']');

    if (head) {
      len--;
      while (len >= 0) {
        String rl = rus[len];
        if (rl == ' ' || rl == ']') {
          len--;
          continue;
        }

        if (_isDigit(rl)) {
          l = rl + l;
        } else if (rl == '-') {
          curMinus = true;
        } else {
          int? curInt = l.isEmpty ? null : int.tryParse(curMinus ? '-$l' : l);
          if (rl == ':') {
            curList.add(curInt);
          } else {
            if (curList.isEmpty) {
              if (curInt == null && rl != '[') break;
              if (curInt != null) indexes.add(curInt);
            } else {
              indexes.add(_Triple(
                curInt,
                curList.last,
                curList.length == 2 ? (curList.first ?? 1) : 1,
              ));
              curList.clear();
            }

            if (rl == '!') {
              split = '!';
              while (len > 0 && rus[len - 1] == ' ') {
                len--;
              }
            }

            if (rl == '[') {
              beforeRule = rus.substring(0, len);
              return;
            }

            if (rl != ',') break;
          }
          l = '';
          curMinus = false;
        }
        len--;
      }
    } else {
      while (len > 0) {
        len--;
        String rl = rus[len];
        if (rl == ' ') continue;

        if (_isDigit(rl)) {
          l = rl + l;
        } else if (rl == '-') {
          curMinus = true;
        } else {
          if (rl == '!' || rl == '.' || rl == ':') {
            final val = int.tryParse(curMinus ? '-$l' : l);
            if (val == null) {
              len++; // Go back one character to include it in beforeRule
              break;
            }
            indexDefault.add(val);
            if (rl != ':') {
              split = rl;
              beforeRule = rus.substring(0, len);
              return;
            }
          } else {
            break;
          }
          l = '';
          curMinus = false;
        }
      }
    }
    split = ' ';
    beforeRule = rus;
  }

  bool _isDigit(String s) => RegExp(r'^\d$').hasMatch(s);
}

class _Triple {
  final int? first;
  final int? second;
  final int third;
  _Triple(this.first, this.second, this.third);
}
