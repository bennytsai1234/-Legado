import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/book_source.dart';
import 'source_manager_provider.dart';
import '../../core/database/dao/book_source_dao.dart';

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
  final _formKey = GlobalKey<FormState>();

  // Controllers for basic info
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _groupController;
  late TextEditingController _commentController;
  late TextEditingController _loginUrlController;
  late TextEditingController _headerController;
  late TextEditingController _exploreUrlController;
  late TextEditingController _searchUrlController;

  // JSON controller
  late TextEditingController _jsonController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _editingSource =
        widget.source != null
            ? BookSource.fromJson(widget.source!.toJson())
            : BookSource(bookSourceUrl: '', bookSourceName: '');

    _initControllers();
    _updateJsonFromForm();
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

  void _updateJsonFromForm() {
    _syncSourceFromForm();
    const encoder = JsonEncoder.withIndent('  ');
    _jsonController.text = encoder.convert(_editingSource.toJson());
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

  bool _updateFormFromJson() {
    try {
      final json = jsonDecode(_jsonController.text);
      setState(() {
        _editingSource = BookSource.fromJson(json);
        _nameController.text = _editingSource.bookSourceName;
        _urlController.text = _editingSource.bookSourceUrl;
        _groupController.text = _editingSource.bookSourceGroup ?? '';
        _commentController.text = _editingSource.bookSourceComment ?? '';
        _loginUrlController.text = _editingSource.loginUrl ?? '';
        _headerController.text = _editingSource.header ?? '';
        _exploreUrlController.text = _editingSource.exploreUrl ?? '';
        _searchUrlController.text = _editingSource.searchUrl ?? '';
      });
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON 格式錯誤: $e')),
      );
      return false;
    }
  }

  Future<void> _save() async {
    if (_tabController.index == 1) {
      if (!_updateFormFromJson()) return;
    } else {
      _syncSourceFromForm();
    }

    if (_editingSource.bookSourceUrl.isEmpty || _editingSource.bookSourceName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('書源名稱和 URL 不能為空')),
      );
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
          IconButton(icon: const Icon(Icons.bug_report), tooltip: '偵錯控制台', onPressed: _showDebugConsole),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '表單'), Tab(text: 'JSON')],
          onTap: (index) {
            if (index == 1) _updateJsonFromForm();
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFormTab(), _buildJsonTab()],
      ),
    );
  }

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildSection('基本資訊', [
              _buildTextField('名稱', _nameController),
              _buildTextField('URL (唯一識別)', _urlController),
              _buildTextField('分組', _groupController),
              _buildTextField('說明', _commentController, maxLines: 2),
              _buildTextField('登入 URL', _loginUrlController),
              _buildTextField('Header (JSON)', _headerController, maxLines: 2),
            ]),
            _buildSection('搜尋與發現', [
              _buildTextField('搜尋 URL', _searchUrlController),
              _buildTextField('發現 URL', _exploreUrlController, maxLines: 2),
            ]),
            _buildRuleSection('搜尋規則', _editingSource.ruleSearch ?? SearchRule(), (r) => _editingSource.ruleSearch = r as SearchRule),
            _buildRuleSection('發現規則', _editingSource.ruleExplore ?? ExploreRule(), (r) => _editingSource.ruleExplore = r as ExploreRule),
            _buildRuleSection('詳情規則', _editingSource.ruleBookInfo ?? BookInfoRule(), (r) => _editingSource.ruleBookInfo = r as BookInfoRule),
            _buildRuleSection('目錄規則', _editingSource.ruleToc ?? TocRule(), (r) => _editingSource.ruleToc = r as TocRule),
            _buildRuleSection('正文規則', _editingSource.ruleContent ?? ContentRule(), (r) => _editingSource.ruleContent = r as ContentRule),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonTab() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _jsonController,
        maxLines: null,
        expands: true,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: '輸入書源 JSON...',
        ),
      ),
    );
  }

  void _showDebugConsole() {
    if (_tabController.index == 1) {
      if (!_updateFormFromJson()) return;
    } else {
      _syncSourceFromForm();
    }
    
    final logs = <String>['開始偵錯...', '套用書源: ${_editingSource.bookSourceName}'];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('偵錯控制台', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                logs.add('>>> 執行搜尋測試...');
                              });
                              // 這裡未來可以接入真實的 BookSourceService 進行單步測試
                              Future.delayed(const Duration(seconds: 1), () {
                                if (mounted) {
                                  setModalState(() {
                                    logs.add('請求 URL: ${_editingSource.searchUrl}');
                                    logs.add('搜尋結果: 模擬成功 (尚未串接真實解析邏輯)');
                                  });
                                }
                              });
                            }, 
                            child: const Text('測試搜尋')
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        ],
                      )
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.all(8),
                      child: ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          return Text(
                            logs[index],
                            style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildRuleSection(String title, dynamic rule, Function(dynamic) onUpdate) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: _buildRuleFields(rule, onUpdate),
    );
  }

  List<Widget> _buildRuleFields(dynamic rule, Function(dynamic) onUpdate) {
    final List<Widget> fields = [];
    final json = rule.toJson() as Map<String, dynamic>;
    
    json.forEach((key, value) {
      final controller = TextEditingController(text: value?.toString() ?? '');
      fields.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: key, border: const UnderlineInputBorder()),
            onChanged: (val) {
              json[key] = val;
              // Reconstruct rule object
              if (rule is SearchRule) {
                onUpdate(SearchRule.fromJson(json));
              } else if (rule is ExploreRule) {
                onUpdate(ExploreRule.fromJson(json));
              } else if (rule is BookInfoRule) {
                onUpdate(BookInfoRule.fromJson(json));
              } else if (rule is TocRule) {
                onUpdate(TocRule.fromJson(json));
              } else if (rule is ContentRule) {
                onUpdate(ContentRule.fromJson(json));
              }
            },
          ),
        ),
      );
    });
    
    return fields;
  }
}
