import 'package:flutter/foundation.dart';
import '../../core/models/dict_rule.dart';
import '../../core/services/dict_service.dart';

class DictProvider with ChangeNotifier {
  final DictService _service = DictService();
  
  List<DictRule> _rules = [];
  List<DictRule> get rules => _rules;
  
  List<DictRule> _allRules = [];
  List<DictRule> get allRules => _allRules;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _result = "";
  String get result => _result;
  
  Future<void> loadRules() async {
    _allRules = await _service.getAllRules();
    _rules = _allRules.where((r) => r.enabled).toList();
    notifyListeners();
  }
  
  Future<void> search(String word) async {
    if (_rules.isEmpty) await loadRules();
    if (_rules.isEmpty) return;
    
    _isLoading = true;
    _result = "";
    notifyListeners();
    
    try {
      // 預設用第一個啟用的規則
      final rule = _rules.first;
      _result = await _service.search(rule, word);
    } catch (e) {
      _result = "搜索失敗: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleRule(DictRule rule) async {
    rule.enabled = !rule.enabled;
    await _service.saveRule(rule);
    await loadRules();
  }

  Future<void> saveRule(DictRule rule) async {
    await _service.saveRule(rule);
    await loadRules();
  }

  Future<void> deleteRule(DictRule rule) async {
    await _service.deleteRule(rule.name);
    await loadRules();
  }
}
