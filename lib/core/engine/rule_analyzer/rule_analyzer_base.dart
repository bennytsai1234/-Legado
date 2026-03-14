/// RuleAnalyzer 的基礎狀態與核心掃描定義
abstract class RuleAnalyzerBase {
  final String _queue;
  int _pos = 0;
  int _start = 0;
  int _startX = 0;
  final bool _isCode;

  List<String> _rule = [];
  int _step = 0;
  String elementsType = '';

  static const int _esc = 92;

  RuleAnalyzerBase(this._queue, {bool isCode = false}) : _isCode = isCode;

  void trim() {
    if (_pos < _queue.length && (_queue[_pos] == '@' || _queue.codeUnitAt(_pos) < 33)) {
      _pos++;
      while (_pos < _queue.length && (_queue[_pos] == '@' || _queue.codeUnitAt(_pos) < 33)) {
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

  bool consumeTo(String seq) {
    _start = _pos;
    if (_pos >= _queue.length) return false;
    final offset = _queue.indexOf(seq, _pos);
    if (offset != -1) {
      _pos = offset;
      return true;
    }
    return false;
  }

  bool consumeToAny(List<String> seq) {
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

  int findToAny(List<String> seq) {
    int pos = _pos;
    while (pos < _queue.length) {
      for (final s in seq) {
        if (_queue[pos] == s) return pos;
      }
      pos++;
    }
    return -1;
  }
}
