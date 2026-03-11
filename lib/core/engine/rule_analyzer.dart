/// RuleAnalyzer - 規則字串切割引擎
/// 對應 Android: model/analyzeRule/RuleAnalyzer.kt (15KB)
class RuleAnalyzer {
  final String _queue; // 被處理字串
  int _pos = 0; // 當前處理到的位置
  int _start = 0; // 當前處理欄位的開始
  int _startX = 0; // 當前規則的開始
  final bool _isCode;

  List<String> _rule = []; // 分割出的規則列表
  int _step = 0; // 分隔字元的長度
  String elementsType = ''; // 當前分割字串

  static const int _esc = 92; // '\\'

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

  /// 拉出一個非內嵌代碼平衡組 (高度還原 Android chompCodeBalanced)
  bool _chompCodeBalanced(String open, String close) {
    int pos = _pos;
    int depth = 0;
    int otherDepth = 0;
    bool inSingleQuote = false;
    bool inDoubleQuote = false;

    do {
      if (pos >= _queue.length) break;
      final c = _queue[pos++];
      if (c.codeUnitAt(0) != _esc) {
        if (c == '\'' && !inDoubleQuote) inSingleQuote = !inSingleQuote;
        else if (c == '"' && !inSingleQuote) inDoubleQuote = !inDoubleQuote;

        if (inSingleQuote || inDoubleQuote) continue;

        if (c == '[') depth++;
        else if (c == ']') depth--;
        else if (depth == 0) {
          if (c == open) otherDepth++;
          else if (c == close) otherDepth--;
        }
      } else {
        pos++; // Skip escaped char
      }
    } while (depth > 0 || otherDepth > 0);

    if (depth > 0 || otherDepth > 0) return false;
    _pos = pos;
    return true;
  }

  /// 拉出一個規則平衡組 (高度還原 Android chompRuleBalanced)
  bool _chompRuleBalanced(String open, String close) {
    int pos = _pos;
    int depth = 0;
    bool inSingleQuote = false;
    bool inDoubleQuote = false;

    do {
      if (pos >= _queue.length) break;
      final c = _queue[pos++];
      if (c == '\'' && !inDoubleQuote) inSingleQuote = !inSingleQuote;
      else if (c == '"' && !inSingleQuote) inDoubleQuote = !inDoubleQuote;

      if (inSingleQuote || inDoubleQuote) continue;
      else if (c == '\\') { pos++; continue; }

      if (c == open) depth++;
      else if (c == close) depth--;
    } while (depth > 0);

    if (depth > 0) return false;
    _pos = pos;
    return true;
  }

  bool _chompBalanced(String open, String close) {
    return _isCode ? _chompCodeBalanced(open, close) : _chompRuleBalanced(open, close);
  }

  /// 分割規則 (高度還原 Android splitRule)
  List<String> splitRule(List<String> split) {
    if (split.length == 1) {
      elementsType = split[0];
      if (!_consumeTo(elementsType)) {
        _rule.add(_queue.substring(_startX));
        return _rule;
      } else {
        _step = elementsType.length;
        return _splitRuleRecursive();
      }
    } else if (!_consumeToAny(split)) {
      _rule.add(_queue.substring(_startX));
      return _rule;
    }

    final end = _pos;
    _pos = _start;

    while (true) {
      final st = _findToAny(['[', '(']);
      if (st == -1 || st > end) {
        _rule = [_queue.substring(_startX, end)];
        elementsType = _queue.substring(end, end + _step);
        _pos = end + _step;
        while (_consumeTo(elementsType)) {
          _rule.add(_queue.substring(_start, _pos));
          _pos += _step;
        }
        _rule.add(_queue.substring(_pos));
        return _rule;
      }

      _pos = st;
      final next = _queue[_pos] == '[' ? ']' : ')';
      if (!_chompBalanced(_queue[_pos], next)) return [_queue]; // Unbalanced fallback

      if (end <= _pos) break;
    }

    _start = _pos;
    return splitRule(split);
  }

  List<String> _splitRuleRecursive() {
    while (true) {
      final end = _pos;
      _pos = _start;

      while (true) {
        final st = _findToAny(['[', '(']);
        if (st == -1 || st > end) {
          _rule.add(_queue.substring(_startX, end));
          _pos = end + _step;
          while (_consumeTo(elementsType)) {
            _rule.add(_queue.substring(_start, _pos));
            _pos += _step;
          }
          _rule.add(_queue.substring(_pos));
          return _rule;
        }

        _pos = st;
        final next = _queue[_pos] == '[' ? ']' : ')';
        if (!_chompBalanced(_queue[_pos], next)) break;
        if (end <= _pos) break;
      }

      _start = _pos;
      if (!_consumeTo(elementsType)) {
        _rule.add(_queue.substring(_startX));
        return _rule;
      }
    }
  }

  /// 替換內嵌規則 (高度還原 Android innerRuleRange 平衡版)
  String innerRuleRange(String startStr, String endStr, {required String? Function(String) fr}) {
    final st = StringBuffer();
    while (_consumeTo(startStr)) {
      final posPre = _pos;
      _pos += startStr.length;
      
      // 如果是括號類起始，使用平衡組檢測 (解決 {{js:{}}} 嵌套問題)
      bool balanced = false;
      if (startStr.contains('{')) {
        balanced = _chompCodeBalanced('{', '}');
      } else if (startStr.contains('[')) {
        balanced = _chompCodeBalanced('[', ']');
      } else {
        balanced = _consumeTo(endStr);
      }

      if (balanced) {
        final content = _queue.substring(posPre + startStr.length, _pos - (startStr.contains('{') ? 1 : 0));
        final frv = fr(content);
        if (frv != null) {
          st.write(_queue.substring(_startX, posPre));
          st.write(frv);
          if (startStr.contains('{')) {
            // _pos 已經在 } 之後
          } else {
            _pos += endStr.length;
          }
          _startX = _pos;
          continue;
        }
      }
      // 不平衡或是普通字串，跳過此處繼續
      _pos = posPre + startStr.length;
    }

    if (_startX == 0) return _queue;
    st.write(_queue.substring(_startX));
    return st.toString();
  }
}
