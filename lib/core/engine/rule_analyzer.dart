/// RuleAnalyzer - 規則字串切割引擎
/// 對應 Android: model/analyzeRule/RuleAnalyzer.kt (15KB)
class RuleAnalyzer {
  final String _queue;
  int _pos = 0; 
  int _start = 0; 
  int _startX = 0; 
  final bool _isCode;

  List<String> _rule = [];
  int _step = 0;
  String elementsType = '';

  static const int _esc = 92;

  RuleAnalyzer(String data, {bool isCode = false})
    : _queue = data,
      _isCode = isCode;

  void trim() {
    if (_pos < _queue.length &&
        (_queue[_pos] == '@' || _queue.codeUnitAt(_pos) < 33)) {
      _pos++;
      while (_pos < _queue.length &&
          (_queue[_pos] == '@' || _queue.codeUnitAt(_pos) < 33)) {
        _pos++;
      }
      _start = _pos;
      _startX = _pos;
    }
  }

  void reSetPos() {
    _pos = 0;
    _startX = 0;
    _start = 0;
    _rule = [];
  }

  bool _consumeTo(String seq) {
    _start = _pos;
    if (_pos >= _queue.length) return false;
    final offset = _queue.indexOf(seq, _pos);
    if (offset != -1) {
      _pos = offset;
      return true;
    }
    return false;
  }

  bool _consumeToAny(List<String> seq) {
    int pos = _pos;
    while (pos < _queue.length) {
      for (final s in seq) {
        if (_queue.startsWith(s, pos)) {
          _step = s.length;
          _pos = pos;
          return true;
        }
      }
      pos++;
    }
    return false;
  }

  int _findToAny(List<String> seq) {
    int pos = _pos;
    while (pos < _queue.length) {
      for (final s in seq) {
        if (_queue[pos] == s) return pos;
      }
      pos++;
    }
    return -1;
  }

  bool _chompCodeBalanced(String open, String close) {
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
      if (c.codeUnitAt(0) != _esc) {
        if (c == "'" && !inDoubleQuote) inSingleQuote = !inSingleQuote;
        else if (c == '"' && !inSingleQuote) inDoubleQuote = !inDoubleQuote;
        if (inSingleQuote || inDoubleQuote) continue;
        if (c == '[') depth++;
        else if (c == ']') depth--;
        else if (depth == 0) {
          if (c == openChar) otherDepth++;
          else if (c == closeChar) otherDepth--;
        }
      } else if (pos < _queue.length) pos++;
    } while (depth > 0 || otherDepth > 0);

    if (depth > 0 || otherDepth > 0) return false;
    _pos = pos;
    return true;
  }

  bool _chompRuleBalanced(String open, String close) {
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
      else if (c == r'\') { if (pos < _queue.length) pos++; continue; }
      if (c == openChar) depth++;
      else if (c == closeChar) depth--;
    } while (depth > 0);

    if (depth > 0) return false;
    _pos = pos;
    return true;
  }

  bool _chompBalanced(String open, String close) {
    return _isCode ? _chompCodeBalanced(open, close) : _chompRuleBalanced(open, close);
  }

  List<String> splitRule(List<String> split) {
    _rule = [];
    _start = _pos;
    _startX = _pos;
    
    // 多分隔符切分
    while (true) {
      if (!_consumeToAny(split)) {
        _rule.add(_queue.substring(_startX));
        return _rule;
      }

      final end = _pos;
      _pos = _start;

      bool skipMatch = false;
      while (end > _pos) {
        final st = _findToAny(['[', '(']);
        if (st == -1 || st > end) break;

        _pos = st;
        final next = _queue[_pos] == '[' ? ']' : ')';
        if (!_chompBalanced(_queue[_pos], next)) return [_queue];

        if (end <= _pos) {
          skipMatch = true;
          break;
        }
      }

      if (!skipMatch) {
        _rule.add(_queue.substring(_startX, end));
        elementsType = _queue.substring(end, end + _step);
        _pos = end + _step;
        _startX = _pos;
        _start = _pos;
        
        // 轉向單一分隔符切分 (matching elementsType)
        return _splitRuleSingle();
      }

      _start = _pos;
      _pos = _start; // continue searching from after skipped bracket
    }
  }

  List<String> _splitRuleSingle() {
    _step = elementsType.length;
    while (true) {
      if (!_consumeTo(elementsType)) {
        _rule.add(_queue.substring(_startX));
        return _rule;
      }

      final end = _pos;
      _pos = _start;

      bool skipMatch = false;
      while (end > _pos) {
        final st = _findToAny(['[', '(']);
        if (st == -1 || st > end) break;

        _pos = st;
        final next = _queue[_pos] == '[' ? ']' : ')';
        if (!_chompBalanced(_queue[_pos], next)) break;

        if (end <= _pos) {
          skipMatch = true;
          break;
        }
      }

      if (!skipMatch) {
        _rule.add(_queue.substring(_startX, end));
        _pos = end + _step;
        _startX = _pos;
        _start = _pos;
      } else {
        _start = _pos;
        // loop will call _consumeTo which starts from current _pos
      }
    }
  }

  String innerRuleRange(String startStr, String endStr, {required String? Function(String) fr}) {
    final st = StringBuffer();
    while (_consumeTo(startStr)) {
      final posPre = _pos;
      _pos += startStr.length;
      bool balanced = false;
      if (startStr.contains('{')) {
        _pos = _queue.indexOf('{', posPre);
        balanced = _chompCodeBalanced('{', '}');
      } else if (startStr.contains('[')) {
        _pos = _queue.indexOf('[', posPre);
        balanced = _chompCodeBalanced('[', ']');
      } else {
        balanced = _consumeTo(endStr);
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
