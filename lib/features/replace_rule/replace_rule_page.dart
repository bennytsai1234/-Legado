import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'replace_rule_provider.dart';
import '../../core/models/replace_rule.dart';
import 'replace_rule_edit_page.dart';

class ReplaceRulePage extends StatelessWidget {
  const ReplaceRulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReplaceRuleProvider(),
      child: Consumer<ReplaceRuleProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('替換規則'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _navigateToEdit(context, provider),
                ),
              ],
            ),
            body: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ReorderableListView.builder(
                    itemCount: provider.rules.length,
                    onReorder: provider.reorder,
                    itemBuilder: (context, index) {
                      final rule = provider.rules[index];
                      return _buildRuleItem(context, provider, rule, index);
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildRuleItem(BuildContext context, ReplaceRuleProvider provider,
      ReplaceRule rule, int index) {
    return ListTile(
      key: ValueKey(rule.id),
      title: Text(rule.name),
      subtitle: Text(
        '${rule.pattern} -> ${rule.replacement}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: rule.isEnabled,
            onChanged: (_) => provider.toggleEnabled(rule),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context, provider, rule: rule),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirm(context, provider, rule),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context, ReplaceRuleProvider provider,
      {ReplaceRule? rule}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReplaceRuleEditPage(
          rule: rule,
          onSave: (newRule) {
            if (rule == null) {
              provider.addRule(newRule);
            } else {
              provider.updateRule(newRule);
            }
          },
        ),
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, ReplaceRuleProvider provider, ReplaceRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除規則「${rule.name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteRule(rule.id);
              Navigator.pop(context);
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
