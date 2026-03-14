import 'rule_analyzer_base.dart';
import 'rule_analyzer_match.dart';

/// RuleAnalyzer 的規則切分邏輯擴展
mixin RuleAnalyzerSplit on RuleAnalyzerBase, RuleAnalyzerMatch {
  List<String> splitRule(List<String> split) {
    _rule = [];
    _start = _pos;
    _startX = _pos;

    while (true) {
      if (!consumeToAny(split)) {
        _rule.add(_queue.substring(_startX));
        return _rule;
      }

      final end = _pos;
      _pos = _start;

      bool skipMatch = false;
      while (end > _pos) {
        final st = findToAny(['[', '(']);
        if (st == -1 || st > end) break;

        _pos = st;
        final next = _queue[_pos] == '[' ? ']' : ')';
        if (!chompBalanced(_queue[_pos], next)) return [_queue];

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
        return splitRuleSingle();
      }

      _start = _pos;
      _pos = _start;
    }
  }

  List<String> splitRuleSingle() {
    _step = elementsType.length;
    while (true) {
      if (!consumeTo(elementsType)) {
        _rule.add(_queue.substring(_startX));
        return _rule;
      }

      final end = _pos;
      _pos = _start;

      bool skipMatch = false;
      while (end > _pos) {
        final st = findToAny(['[', '(']);
        if (st == -1 || st > end) break;

        _pos = st;
        final next = _queue[_pos] == '[' ? ']' : ')';
        if (!chompBalanced(_queue[_pos], next)) break;

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
      }
    }
  }
}
