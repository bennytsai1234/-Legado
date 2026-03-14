import 'rule_analyzer_base.dart';

/// RuleAnalyzer 的括號匹配邏輯擴展
mixin RuleAnalyzerMatch on RuleAnalyzerBase {
  bool chompCodeBalanced(String open, String close) {
    int pos = _pos;
    int depth = 0;
    int otherDepth = 0;
    bool inSingleQuote = false;
    bool inDoubleQuote = false;
    final openChar = open[0];
    final closeChar = close[0];

    do {
      if (pos >= _queue.length) break;
      final c = _queue[pos++];
      if (c.codeUnitAt(0) != RuleAnalyzerBase._esc) {
        if (c == "'" && !inDoubleQuote) inSingleQuote = !inSingleQuote;
        else if (c == '"' && !inSingleQuote) inDoubleQuote = !inDoubleQuote;
        
        if (inSingleQuote || inDoubleQuote) continue;
        
        if (c == '[') depth++;
        else if (c == ']') depth--;
        else if (depth == 0) {
          if (c == openChar) otherDepth++;
          else if (c == closeChar) otherDepth--;
        }
      } else if (pos < _queue.length) {
        pos++;
      }
    } while (depth > 0 || otherDepth > 0);

    if (depth > 0 || otherDepth > 0) return false;
    _pos = pos;
    return true;
  }

  bool chompRuleBalanced(String open, String close) {
    int pos = _pos;
    int depth = 0;
    bool inSingleQuote = false;
    bool inDoubleQuote = false;
    final openChar = open[0];
    final closeChar = close[0];

    do {
      if (pos >= _queue.length) break;
      final c = _queue[pos++];
      if (c == "'" && !inDoubleQuote) inSingleQuote = !inSingleQuote;
      else if (c == '"' && !inSingleQuote) inDoubleQuote = !inDoubleQuote;
      
      if (inSingleQuote || inDoubleQuote) continue;
      else if (c == r'\') {
        if (pos < _queue.length) pos++;
        continue;
      }
      if (c == openChar) depth++;
      else if (c == closeChar) depth--;
    } while (depth > 0);

    if (depth > 0) return false;
    _pos = pos;
    return true;
  }

  bool chompBalanced(String open, String close) {
    return _isCode ? chompCodeBalanced(open, close) : chompRuleBalanced(open, close);
  }
}
