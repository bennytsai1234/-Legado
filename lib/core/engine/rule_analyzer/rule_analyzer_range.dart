import 'rule_analyzer_base.dart';
import 'rule_analyzer_match.dart';

/// RuleAnalyzer 的範圍提取邏輯擴展
mixin RuleAnalyzerRange on RuleAnalyzerBase, RuleAnalyzerMatch {
  String innerRuleRange(String startStr, String endStr, {required String? Function(String) fr}) {
    final st = StringBuffer();
    while (consumeTo(startStr)) {
      final posPre = _pos;
      _pos += startStr.length;
      bool balanced = false;
      
      if (startStr.contains('{')) {
        final nextBrace = _queue.indexOf('{', posPre);
        if (nextBrace != -1) {
          _pos = nextBrace;
          balanced = chompCodeBalanced('{', '}');
        }
      } else if (startStr.contains('[')) {
        final nextBracket = _queue.indexOf('[', posPre);
        if (nextBracket != -1) {
          _pos = nextBracket;
          balanced = chompCodeBalanced('[', ']');
        }
      } else {
        balanced = consumeTo(endStr);
        if (balanced) _pos += endStr.length;
      }

      if (balanced) {
        final content = _queue.substring(posPre + startStr.length, _pos - endStr.length);
        final frv = fr(content);
        if (frv != null) {
          st.write(_queue.substring(_startX, posPre));
          st.write(frv);
          _startX = _pos;
          continue;
        }
      }
      _pos = posPre + startStr.length;
    }
    
    if (_startX == 0) return _queue;
    st.write(_queue.substring(_startX));
    return st.toString();
  }

  String innerRule(String startStr, {required String? Function(String) fr}) {
    String endStr = "}";
    if (startStr.startsWith('{{')) endStr = "}}";
    else if (startStr.startsWith('[')) endStr = "]";
    return innerRuleRange(startStr, endStr, fr: fr);
  }
}
