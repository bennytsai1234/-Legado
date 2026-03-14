import 'package:html/dom.dart';

class SourceRule {
  bool isCss = false;
  late String elementsRule;

  SourceRule(String ruleStr) {
    if (ruleStr.toUpperCase().startsWith('@CSS:')) {
      isCss = true;
      elementsRule = ruleStr.substring(5).trim();
    } else {
      elementsRule = ruleStr;
    }
  }
}

class ElementsSingle {
  String split = '.';
  String beforeRule = '';
  final List<int> indexDefault = [];
  final List<dynamic> indexes = [];

  List<Element> getElementsSingle(Element temp, String rule) {
    findIndexSet(rule);

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
        elements =
            temp.querySelectorAll('*').where((el) {
              return el.nodes.any(
                (n) =>
                    n.nodeType == Node.TEXT_NODE && n.text!.contains(rules[1]),
              );
            }).toList();
      } else {
        try {
          elements = temp.querySelectorAll(beforeRule);
        } catch (e) {
          elements = [];
        }
      }
    }

    final len = elements.length;
    if (len == 0) return [];

    final lastIndexes =
        indexDefault.isNotEmpty ? indexDefault.length - 1 : indexes.length - 1;
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
        if (idx is Triple) {
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

  void findIndexSet(String rule) {
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
              indexes.add(
                Triple(
                  curInt,
                  curList.last,
                  curList.length == 2 ? (curList.first ?? 1) : 1,
                ),
              );
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
         head = false; // reset head if rule is complex
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
              len++;
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

class Triple {
  final int? first;
  final int? second;
  final int third;
  Triple(this.first, this.second, this.third);
}
