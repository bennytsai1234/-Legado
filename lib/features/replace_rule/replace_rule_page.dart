import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'replace_rule_provider.dart';
import '../../core/models/replace_rule.dart';

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
                  onPressed: () => _showEditDialog(context, provider),
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
            onPressed: () => _showEditDialog(context, provider, rule: rule),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirm(context, provider, rule),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ReplaceRuleProvider provider,
      {ReplaceRule? rule}) {
    final nameController = TextEditingController(text: rule?.name ?? '');
    final patternController = TextEditingController(text: rule?.pattern ?? '');
    final replacementController =
        TextEditingController(text: rule?.replacement ?? '');
    bool isRegex = rule?.isRegex ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(rule == null ? '新增規則' : '編輯規則'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '名稱'),
                ),
                TextField(
                  controller: patternController,
                  decoration: const InputDecoration(labelText: '正則/替換目標'),
                ),
                TextField(
                  controller: replacementController,
                  decoration: const InputDecoration(labelText: '替換為'),
                ),
                CheckboxListTile(
                  title: const Text('是否為正則'),
                  value: isRegex,
                  onChanged: (val) => setState(() => isRegex = val ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final newRule = ReplaceRule(
                  id: rule?.id ?? 0,
                  name: nameController.text,
                  pattern: patternController.text,
                  replacement: replacementController.text,
                  isRegex: isRegex,
                  isEnabled: rule?.isEnabled ?? true,
                  order: rule?.order ?? provider.rules.length,
                );
                if (rule == null) {
                  provider.addRule(newRule);
                } else {
                  provider.updateRule(newRule);
                }
                Navigator.pop(context);
              },
              child: const Text('儲存'),
            ),
          ],
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
