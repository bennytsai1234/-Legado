import 'package:flutter/material.dart';
import '../../core/models/replace_rule.dart';

class ReplaceRuleEditPage extends StatefulWidget {
  final ReplaceRule? rule;
  final Function(ReplaceRule) onSave;

  const ReplaceRuleEditPage({super.key, this.rule, required this.onSave});

  @override
  State<ReplaceRuleEditPage> createState() => _ReplaceRuleEditPageState();
}

class _ReplaceRuleEditPageState extends State<ReplaceRuleEditPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameCtrl;
  late TextEditingController _groupCtrl;
  late TextEditingController _patternCtrl;
  late TextEditingController _replacementCtrl;
  late TextEditingController _scopeCtrl;
  late TextEditingController _excludeScopeCtrl;
  late TextEditingController _timeoutCtrl;

  bool _isEnabled = true;
  bool _isRegex = true;
  bool _scopeTitle = false;
  bool _scopeContent = true;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _nameCtrl = TextEditingController(text: rule?.name ?? '');
    _groupCtrl = TextEditingController(text: rule?.group ?? '');
    _patternCtrl = TextEditingController(text: rule?.pattern ?? '');
    _replacementCtrl = TextEditingController(text: rule?.replacement ?? '');
    _scopeCtrl = TextEditingController(text: rule?.scope ?? '');
    _excludeScopeCtrl = TextEditingController(text: rule?.excludeScope ?? '');
    _timeoutCtrl = TextEditingController(text: (rule?.timeoutMillisecond ?? 3000).toString());

    _isEnabled = rule?.isEnabled ?? true;
    _isRegex = rule?.isRegex ?? true;
    _scopeTitle = rule?.scopeTitle ?? false;
    _scopeContent = rule?.scopeContent ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _groupCtrl.dispose();
    _patternCtrl.dispose();
    _replacementCtrl.dispose();
    _scopeCtrl.dispose();
    _excludeScopeCtrl.dispose();
    _timeoutCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final rule = ReplaceRule(
        id: widget.rule?.id ?? 0,
        name: _nameCtrl.text.trim(),
        group: _groupCtrl.text.trim(),
        pattern: _patternCtrl.text.trim(),
        replacement: _replacementCtrl.text,
        scope: _scopeCtrl.text.trim(),
        excludeScope: _excludeScopeCtrl.text.trim(),
        timeoutMillisecond: int.tryParse(_timeoutCtrl.text) ?? 3000,
        isEnabled: _isEnabled,
        isRegex: _isRegex,
        scopeTitle: _scopeTitle,
        scopeContent: _scopeContent,
        order: widget.rule?.order ?? 0,
      );

      if (!rule.isValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正則表達式語法錯誤，請檢查！')),
        );
        return;
      }

      widget.onSave(rule);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rule == null ? '新增替換規則' : '編輯替換規則'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            tooltip: '儲存',
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '規則名稱 *'),
              validator: (v) => v!.trim().isEmpty ? '名稱不能為空' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _groupCtrl,
              decoration: const InputDecoration(labelText: '分組'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _patternCtrl,
              decoration: const InputDecoration(labelText: '替換正則內容 *'),
              maxLines: 3,
              validator: (v) => v!.trim().isEmpty ? '正則內容不能為空' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _replacementCtrl,
              decoration: const InputDecoration(labelText: '替換為內容'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _scopeCtrl,
              decoration: const InputDecoration(labelText: '作用範圍 (書名/書源URL)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _excludeScopeCtrl,
              decoration: const InputDecoration(labelText: '排除範圍 (書名/書源URL)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _timeoutCtrl,
              decoration: const InputDecoration(labelText: '正則超時時間 (毫秒)'),
              keyboardType: TextInputType.number,
            ),
            const Divider(height: 32),
            SwitchListTile(
              title: const Text('是否啟用'),
              value: _isEnabled,
              onChanged: (v) => setState(() => _isEnabled = v),
            ),
            SwitchListTile(
              title: const Text('啟用正則'),
              value: _isRegex,
              onChanged: (v) => setState(() => _isRegex = v),
            ),
            SwitchListTile(
              title: const Text('作用於標題'),
              value: _scopeTitle,
              onChanged: (v) => setState(() => _scopeTitle = v),
            ),
            SwitchListTile(
              title: const Text('作用於正文'),
              value: _scopeContent,
              onChanged: (v) => setState(() => _scopeContent = v),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
