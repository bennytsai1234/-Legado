import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'source_manager_provider.dart';
import '../../core/models/book_source.dart';

class SourceManagerPage extends StatefulWidget {
  const SourceManagerPage({super.key});

  @override
  State<SourceManagerPage> createState() => _SourceManagerPageState();
}

class _SourceManagerPageState extends State<SourceManagerPage> {
  final TextEditingController _importController = TextEditingController();

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('書源管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SourceManagerProvider>().loadSources(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'url') {
                _showImportDialog(context, isUrl: true);
              } else if (value == 'clipboard') {
                _importFromClipboard(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'url', child: Text('網路匯入')),
              const PopupMenuItem(value: 'clipboard', child: Text('剪貼簿匯入')),
            ],
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildGroupFilter(),
          Expanded(child: _buildSourceList()),
        ],
      ),
    );
  }

  Widget _buildGroupFilter() {
    return Consumer<SourceManagerProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: provider.groups.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final group = provider.groups[index];
              final isSelected = provider.selectedGroup == group;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(group),
                  selected: isSelected,
                  onSelected: (selected) {
                    provider.selectGroup(group);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSourceList() {
    return Consumer<SourceManagerProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.sources.isEmpty) {
          return const Center(child: Text('暫無書源'));
        }
        return ListView.separated(
          itemCount: provider.sources.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final source = provider.sources[index];
            return _buildSourceItem(context, provider, source);
          },
        );
      },
    );
  }

  Widget _buildSourceItem(BuildContext context, SourceManagerProvider provider, BookSource source) {
    return Dismissible(
      key: Key(source.bookSourceUrl),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.deleteSource(source);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已刪除 ${source.bookSourceName}')),
        );
      },
      child: ListTile(
        title: Text(source.bookSourceName),
        subtitle: Text(
          source.bookSourceGroup ?? '未分組',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Switch(
          value: source.enabled,
          onChanged: (value) => provider.toggleEnabled(source),
        ),
        onTap: () {
          // TODO: 編輯書源詳情
        },
      ),
    );
  }

  void _showImportDialog(BuildContext context, {required bool isUrl}) {
    _importController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isUrl ? '網路匯入' : '文本匯入'),
        content: TextField(
          controller: _importController,
          decoration: InputDecoration(
            hintText: isUrl ? '請輸入書源 URL' : '請貼上書源 JSON',
          ),
          maxLines: isUrl ? 1 : 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final provider = context.read<SourceManagerProvider>();
              final input = _importController.text.trim();
              
              if (input.isNotEmpty) {
                int count;
                if (isUrl) {
                  count = await provider.importFromUrl(input);
                } else {
                  count = await provider.importFromText(input);
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(count > 0 ? '成功匯入 $count 個書源' : '匯入失敗')),
                  );
                }
              }
              navigator.pop();
            },
            child: const Text('匯入'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final provider = context.read<SourceManagerProvider>();
      final count = await provider.importFromText(data!.text!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(count > 0 ? '從剪貼簿匯入 $count 個書源' : '剪貼簿無有效書源')),
        );
      }
    }
  }
}
