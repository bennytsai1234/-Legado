/// RuleAnalyzer - 規則字串切割引擎
/// 對應 Android: model/analyzeRule/RuleAnalyzer.kt (15KB)
///
/// 負責解析 Legado 的複合規則，如:
/// rule1 && rule2 || rule3
/// {{javascript}}
/// @put:{key:rule}
/// @get:{key}
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

  /// 修剪當前規則之前的 "@" 或者空白符
  void trim() {
    if (_pos < _queue.length && (_queue[_pos] == '@' || _queue.codeUnitAt(_pos) < 33)) {
      _pos++;
      while (_pos < _queue.length && (_queue[_pos] == '@' || _queue.codeUnitAt(_pos) < 33)) {
        _pos++;
      }
      _start = _pos; // 開始點推移
      _startX = _pos; // 規則起始點推移
    }
  }

  /// 將 pos 重置為 0，方便複用
  void reSetPos() {
    _pos = 0;
    _startX = 0;
    _rule = [];
  }

  /// 從剩餘字串中拉出一個字串，直到但不包括匹配序列
  bool _consumeTo(String seq) {
    _start = _pos; // 將處理到的位置設置為規則起點
    if (_pos >= _queue.length) return false;
    final offset = _queue.indexOf(seq, _pos);
    if (offset != -1) {
      _pos = offset;
      return true;
    }
    return false;
  }

  /// 從剩餘字串中拉出一個字串，直到但不包括匹配序列（匹配參數清單中一項即為匹配），或剩餘字串用完。
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

  /// 找尋多個字元中的任意一個
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

  /// 拉出一個非內嵌代碼平衡組，存在轉義文本
  bool _chompCodeBalanced(String open, String close) {
    int pos = _pos;
    int depth = 0;
    int otherDepth = 0;
    bool inSingleQuote = false;
    bool inDoubleQuote = false;

    do {
      if (pos == _queue.length) break;
      final c = _queue[pos++];
      if (c.codeUnitAt(0) != _esc) {
        if (c == '\'' && !inDoubleQuote) {
          inSingleQuote = !inSingleQuote;
        } else if (c == '"' && !inSingleQuote) {
          inDoubleQuote = !inDoubleQuote;
        }

        if (inSingleQuote || inDoubleQuote) continue;

        if (c == '[') {
          depth++;
        } else if (c == ']') {
          depth--;
        } else if (depth == 0) {
          if (c == open) {
            otherDepth++;
          } else if (c == close) {
            otherDepth--;
          }
        }
      } else {
        pos++;
      }
    } while (depth > 0 || otherDepth > 0);

    if (depth > 0 || otherDepth > 0) {
      return false;
    } else {
      _pos = pos;
      return true;
    }
  }

  /// 拉出一個規則平衡組
  bool _chompRuleBalanced(String open, String close) {
    int pos = _pos;
    int depth = 0;
    bool inSingleQuote = false;
    bool inDoubleQuote = false;

    do {
      if (pos == _queue.length) break;
      final c = _queue[pos++];
      if (c == '\'' && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
      } else if (c == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
      }

      if (inSingleQuote || inDoubleQuote) {
        continue;
      } else if (c == '\\') {
        pos++;
        continue;
      }

      if (c == open) {
        depth++;
      } else if (c == close) {
        depth--;
      }
    } while (depth > 0);

    if (depth > 0) {
      return false;
    } else {
      _pos = pos;
      return true;
    }
  }

  bool _chompBalanced(String open, String close) {
    return _isCode ? _chompCodeBalanced(open, close) : _chompRuleBalanced(open, close);
  }

  /// 分割規則
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
      if (st == -1) {
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

      if (st > end) {
        _rule = [_queue.substring(_startX, end)];
        elementsType = _queue.substring(end, end + _step);
        _pos = end + _step;

        while (_consumeTo(elementsType) && _pos < st) {
          _rule.add(_queue.substring(_start, _pos));
          _pos += _step;
        }

        if (_pos > st) {
          _startX = _start;
          return _splitRuleRecursive();
        } else {
          _rule.add(_queue.substring(_pos));
          return _rule;
        }
      }

      _pos = st;
      final next = _queue[_pos] == '[' ? ']' : ')';
      if (!_chompBalanced(_queue[_pos], next)) {
        throw Error(); // TODO: Better error message
      }

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
        if (st == -1) {
          _rule.add(_queue.substring(_startX, end));
          _pos = end + _step;
          while (_consumeTo(elementsType)) {
            _rule.add(_queue.substring(_start, _pos));
            _pos += _step;
          }
          _rule.add(_queue.substring(_pos));
          return _rule;
        }

        if (st > end) {
          _rule.add(_queue.substring(_startX, end));
          _pos = end + _step;
          while (_consumeTo(elementsType) && _pos < st) {
            _rule.add(_queue.substring(_start, _pos));
            _pos += _step;
          }

          if (_pos > st) {
            _startX = _start;
            // Continue the outer while loop (effectively tailrec)
            break; 
          } else {
            _rule.add(_queue.substring(_pos));
            return _rule;
          }
        }

        _pos = st;
        final next = _queue[_pos] == '[' ? ']' : ')';
        if (!_chompBalanced(_queue[_pos], next)) {
          throw Error();
        }
        if (end <= _pos) break;
      }
      
      if (_pos < end) {
          // This path happens if we broke out to continue outer loop
          continue;
      }

      _start = _pos;
      if (!_consumeTo(elementsType)) {
        _rule.add(_queue.substring(_startX));
        return _rule;
      }
      // loop continues
    }
  }

  /// 替換內嵌規則
  String innerRule(
    String inner, {
    int startStep = 1,
    int endStep = 1,
    required String? Function(String) fr,
  }) {
    final st = StringBuffer();

    while (_consumeTo(inner)) {
      final posPre = _pos;
      if (_chompCodeBalanced('{', '}')) {
        final frv = fr(_queue.substring(posPre + startStep, _pos - endStep));
        if (frv != null && frv.isNotEmpty) {
          st.write(_queue.substring(_startX, posPre));
          st.write(frv);
          _startX = _pos;
          continue;
        }
      }
      _pos += inner.length;
    }

    if (_startX == 0) return "";
    st.write(_queue.substring(_startX));
    return st.toString();
  }

  /// 替換內嵌規則 (字串匹配版)
  String innerRuleRange(
    String startStr,
    String endStr, {
    required String? Function(String) fr,
  }) {
    final st = StringBuffer();
    while (_consumeTo(startStr)) {
      _pos += startStr.length;
      final posPre = _pos;
      if (_consumeTo(endStr)) {
        final frv = fr(_queue.substring(posPre, _pos));
        if (frv != null) {
          st.write(_queue.substring(_startX, posPre - startStr.length));
          st.write(frv);
          _pos += endStr.length;
          _startX = _pos;
        } else {
          // Keep looking after this startStr
          _pos += 1; 
        }
      }
    }

    if (_startX == 0) return _queue;
    st.write(_queue.substring(_startX));
    return st.toString();
  }
}
