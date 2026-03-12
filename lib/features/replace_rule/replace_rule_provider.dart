import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/database/dao/replace_rule_dao.dart';
import '../../core/models/replace_rule.dart';

class ReplaceRuleProvider extends ChangeNotifier {
  final ReplaceRuleDao _dao = ReplaceRuleDao();
  List<ReplaceRule> _rules = [];
  bool _isLoading = false;

  List<ReplaceRule> get rules => _rules;
  bool get isLoading => _isLoading;

  ReplaceRuleProvider() {
    loadRules();
  }

  Future<void> loadRules() async {
    _isLoading = true;
    notifyListeners();
    _rules = await _dao.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRule(ReplaceRule rule) async {
    await _dao.insertOrUpdate(rule);
    await loadRules();
  }

  Future<void> updateRule(ReplaceRule rule) async {
    await _dao.insertOrUpdate(rule);
    await loadRules();
  }

  Future<void> deleteRule(int id) async {
    await _dao.delete(id);
    await loadRules();
  }

  Future<void> toggleEnabled(ReplaceRule rule) async {
    final newState = !rule.isEnabled;
    await _dao.updateEnabled(rule.id, newState);
    rule.isEnabled = newState;
    notifyListeners();
  }

  Future<void> updateOrder(int id, int order) async {
    await _dao.updateOrder(id, order);
    // Don't reload all for every reorder if using ReorderableListView, 
    // but here we just keep it simple.
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final rule = _rules.removeAt(oldIndex);
    _rules.insert(newIndex, rule);
    notifyListeners();

    // Update all orders in DB
    for (int i = 0; i < _rules.length; i++) {
      _rules[i].order = i;
      await _dao.updateOrder(_rules[i].id, i);
    }
  }

  // --- 導入導出擴展 ---
  Future<int> importFromText(String jsonStr) async {
    int count = 0;
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      for (var item in list) {
        if (item is Map<String, dynamic>) {
          final rule = ReplaceRule.fromJson(item);
          await _dao.insertOrUpdate(rule);
          count++;
        }
      }
      if (count > 0) {
        await loadRules();
      }
    } catch (e) {
      debugPrint('匯入規則失敗: $e');
    }
    return count;
  }

  Future<void> exportToClipboard() async {
    try {
      final list = _rules.map((e) => e.toJson()).toList();
      final jsonStr = jsonEncode(list);
      await Clipboard.setData(ClipboardData(text: jsonStr));
    } catch (e) {
      debugPrint('導出規則失敗: $e');
    }
  }
}

