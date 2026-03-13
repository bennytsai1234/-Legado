import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/book_source.dart';
import 'source_manager_provider.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../debug/debug_page.dart';

class SourceEditorPage extends StatefulWidget {
  final BookSource? source;
  const SourceEditorPage({super.key, this.source});

  @override
  State<SourceEditorPage> createState() => _SourceEditorPageState();
}

class _SourceEditorPageState extends State<SourceEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BookSource _editingSource;

  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _groupController;
  late TextEditingController _commentController;
  late TextEditingController _loginUrlController;
  late TextEditingController _headerController;
  late TextEditingController _exploreUrlController;
  late TextEditingController _searchUrlController;
  late TextEditingController _jsonController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _editingSource = widget.source != null
        ? BookSource.fromJson(widget.source!.toJson())
        : BookSource(bookSourceUrl: '', bookSourceName: '');

    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _editingSource.bookSourceName);
    _urlController = TextEditingController(text: _editingSource.bookSourceUrl);
    _groupController = TextEditingController(text: _editingSource.bookSourceGroup);
    _commentController = TextEditingController(text: _editingSource.bookSourceComment);
    _loginUrlController = TextEditingController(text: _editingSource.loginUrl);
    _headerController = TextEditingController(text: _editingSource.header);
    _exploreUrlController = TextEditingController(text: _editingSource.exploreUrl);
    _searchUrlController = TextEditingController(text: _editingSource.searchUrl);
    _jsonController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _urlController.dispose();
    _groupController.dispose();
    _commentController.dispose();
    _loginUrlController.dispose();
    _headerController.dispose();
    _exploreUrlController.dispose();
    _searchUrlController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  void _syncSourceFromForm() {
    _editingSource.bookSourceName = _nameController.text;
    _editingSource.bookSourceUrl = _urlController.text;
    _editingSource.bookSourceGroup = _groupController.text;
    _editingSource.bookSourceComment = _commentController.text;
    _editingSource.loginUrl = _loginUrlController.text;
    _editingSource.header = _headerController.text;
    _editingSource.exploreUrl = _exploreUrlController.text;
    _editingSource.searchUrl = _searchUrlController.text;
  }

  void _updateJsonFromForm() {
    _syncSourceFromForm();
    _jsonController.text = const JsonEncoder.withIndent('  ').convert(_editingSource.toJson());
  }

  bool _updateFormFromJson() {
    try {
      final json = jsonDecode(_jsonController.text);
      setState(() {
        _editingSource = BookSource.fromJson(json);
        _initControllers(); // Refresh all text controllers
      });
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('JSON 格式錯誤: $e')));
      return false;
    }
  }

  Future<void> _save() async {
    if (_tabController.index == 1) { if (!_updateFormFromJson()) return; }
    else { _syncSourceFromForm(); }

    if (_editingSource.bookSourceUrl.isEmpty || _editingSource.bookSourceName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('名稱和 URL 不能為空')));
      return;
    }

    await BookSourceDao().insertOrUpdate(_editingSource);
    if (mounted) {
      context.read<SourceManagerProvider>().loadSources();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.source == null ? '新建書源' : '編輯書源'),
        actions: [
          IconButton(icon: const Icon(Icons.bug_report), onPressed: _showDebugConsole),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: '表單'), Tab(text: 'JSON')], onTap: (i) { if (i == 1) _updateJsonFromForm(); }),
      ),
      body: TabBarView(controller: _tabController, children: [_buildFormTab(), _buildJsonTab()]),
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        child: Column(children: [
          _buildSection('基本資訊', [
            _buildTextField('名稱', _nameController, hint: '書源顯示名稱'),
            _buildTextField('URL', _urlController, hint: '書源首頁位址'),
            _buildTextField('分組', _groupController, hint: '多個分組用逗號隔開'),
            _buildTextField('Header', _headerController, hint: 'JSON 格式的請求頭', maxLines: 2),
          ]),
          _buildSection('搜尋與發現', [
            _buildTextField('搜尋 URL', _searchUrlController, hint: '支援 {{key}} 變數'),
            _buildTextField('發現 URL', _exploreUrlController, hint: '支援分頁與分類', maxLines: 2),
          ]),
          _buildRuleEditor('搜尋規則', _editingSource.ruleSearch ?? SearchRule(), 
            ['bookList', 'name', 'author', 'kind', 'wordCount', 'lastChapter', 'intro', 'coverUrl', 'bookUrl'],
            (m) => _editingSource.ruleSearch = SearchRule.fromJson(m),
            {
              'bookList': '列表規則',
              'bookUrl': '詳情頁連結',
              'coverUrl': '封面圖連結'
            }),
          _buildRuleEditor('詳情規則', _editingSource.ruleBookInfo ?? BookInfoRule(),
            ['name', 'author', 'kind', 'wordCount', 'lastChapter', 'intro', 'coverUrl', 'tocUrl'],
            (m) => _editingSource.ruleBookInfo = BookInfoRule.fromJson(m),
            {}),
          _buildRuleEditor('目錄規則', _editingSource.ruleToc ?? TocRule(),
            ['chapterList', 'chapterName', 'chapterUrl', 'nextPage'],
            (m) => _editingSource.ruleToc = TocRule.fromJson(m),
            {}),
          _buildRuleEditor('正文規則', _editingSource.ruleContent ?? ContentRule(),
            ['content', 'nextPage', 'replaceRegex', 'sourceRegex'],
            (m) => _editingSource.ruleContent = ContentRule.fromJson(m),
            {}),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  Widget _buildRuleEditor(String title, dynamic rule, List<String> allKeys, Function(Map<String, dynamic>) onUpdate, Map<String, String> hints) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: allKeys.map((key) {
            final currentVal = rule.toJson()[key]?.toString() ?? '';
            final ctrl = TextEditingController(text: currentVal);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: key, 
                  helperText: hints[key],
                  isDense: true,
                  border: const UnderlineInputBorder()
                ),
                onChanged: (v) {
                  final map = rule.toJson() as Map<String, dynamic>;
                  map[key] = v;
                  onUpdate(map);
                },
              ),
            );
          }).toList()),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue))),
    ...children, const Divider(),
  ]);

  Widget _buildTextField(String label, TextEditingController ctrl, {String? hint, int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(controller: ctrl, maxLines: maxLines, decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder())),
  );

  Widget _buildJsonTab() => Padding(padding: const EdgeInsets.all(8), child: TextField(controller: _jsonController, maxLines: null, expands: true, style: const TextStyle(fontFamily: 'monospace', fontSize: 12), decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '輸入書源 JSON...')));

  void _showDebugConsole() { _syncSourceFromForm(); Navigator.push(context, MaterialPageRoute(builder: (context) => DebugPage(source: _editingSource))); }
}
