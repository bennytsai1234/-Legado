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
  
  // 調試相關
  final TextEditingController _testInputCtrl = TextEditingController(text: "這是一段測試文字，包含 junk123 內容。");
  String _testResult = "";

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

    // 監聽變動以自動更新調試結果
    _patternCtrl.addListener(_runTest);
    _replacementCtrl.addListener(_runTest);
    _testInputCtrl.addListener(_runTest);
    _runTest();
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
    _testInputCtrl.dispose();
    super.dispose();
  }

  void _runTest() {
    final rule = ReplaceRule(
      pattern: _patternCtrl.text,
      replacement: _replacementCtrl.text,
      isRegex: _isRegex,
    );
    setState(() {
      _testResult = rule.apply(_testInputCtrl.text);
    });
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
              decoration: const InputDecoration(labelText: '規則名稱 *', border: OutlineInputBorder()),
              validator: (v) => v!.trim().isEmpty ? '名稱不能為空' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _groupCtrl,
                    decoration: const InputDecoration(labelText: '分組', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _timeoutCtrl,
                    decoration: const InputDecoration(labelText: '超時 (ms)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _patternCtrl,
              decoration: const InputDecoration(labelText: '替換正則內容 *', border: OutlineInputBorder()),
              maxLines: 3,
              validator: (v) => v!.trim().isEmpty ? '正則內容不能為空' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _replacementCtrl,
              decoration: const InputDecoration(labelText: '替換為內容', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('進階範圍設定', style: TextStyle(fontSize: 14)),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _scopeCtrl,
                    decoration: const InputDecoration(labelText: '作用範圍 (書名/書源URL)', border: OutlineInputBorder()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _excludeScopeCtrl,
                    decoration: const InputDecoration(labelText: '排除範圍 (書名/書源URL)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: [
                _buildChip('已啟用', _isEnabled, (v) => setState(() => _isEnabled = v)),
                _buildChip('正則', _isRegex, (v) {
                  setState(() => _isRegex = v);
                  _runTest();
                }),
                _buildChip('標題', _scopeTitle, (v) => setState(() => _scopeTitle = v)),
                _buildChip('正文', _scopeContent, (v) => setState(() => _scopeContent = v)),
              ],
            ),
            const SizedBox(height: 24),
            _buildDebugSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: value,
      onSelected: onChanged,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDebugSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bug_report, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Text('規則調試', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _testInputCtrl,
            decoration: const InputDecoration(
              labelText: '測試文字',
              hintText: '請輸入要測試的內容',
              isDense: true,
            ),
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Text('替換結果:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _testResult.isEmpty ? "(無結果)" : _testResult,
              style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
