import 'package:flutter/material.dart';
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
    return Consumer<SourceManagerProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(provider.isBatchMode
                ? '已選擇 ${provider.selectedUrls.length} 項'
                : '書源管理'),
            actions: provider.isBatchMode
                ? [
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      tooltip: '全選',
                      onPressed: provider.selectAll,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: '取消',
                      onPressed: provider.toggleBatchMode,
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: '刷新列表',
                      onPressed: provider.loadSources,
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
              if (!provider.isBatchMode) _buildGroupFilter(),
              Expanded(child: _buildSourceList()),
            ],
          ),
          bottomNavigationBar: provider.isBatchMode ? _buildBatchBottomBar(context, provider) : null,
        );
      },
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

  Widget _buildSourceItem(
      BuildContext context, SourceManagerProvider provider, BookSource source) {
    bool isSelected = provider.selectedUrls.contains(source.bookSourceUrl);
    
    // 判斷狀態
    String statusStr = "正常";
    Color statusColor = Colors.grey;
    if (source.respondTime < 0) {
      statusStr = "失效";
      statusColor = Colors.red;
    } else if (source.respondTime > 0) {
      statusStr = "${source.respondTime}ms";
      statusColor = source.respondTime < 1000 ? Colors.green : Colors.orange;
    }

    final tile = ListTile(
      leading: provider.isBatchMode ? Icon(
        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isSelected ? Colors.blue : Colors.grey,
      ) : null,
      title: Text(source.bookSourceName),
      subtitle: Row(
        children: [
          Text(
            source.bookSourceGroup ?? '未分組',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Text(
            statusStr,
            style: TextStyle(fontSize: 12, color: statusColor),
          ),
        ],
      ),
      trailing: provider.isBatchMode ? null : Switch(
        value: source.enabled,
        onChanged: (value) => provider.toggleEnabled(source),
      ),
      onTap: () {
        if (provider.isBatchMode) {
          provider.toggleSelect(source.bookSourceUrl);
        } else {
          // TODO: 進入編輯頁面
        }
      },
      onLongPress: () {
        if (!provider.isBatchMode) {
          provider.toggleBatchMode();
          provider.toggleSelect(source.bookSourceUrl);
        }
      },
    );

    if (provider.isBatchMode) return tile;

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
            SnackBar(content: Text('已刪除 ${source.bookSourceName}')));
      },
      child: tile,
    );
  }

  Widget _buildBatchBottomBar(BuildContext context, SourceManagerProvider provider) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.fact_check),
            label: const Text('校驗'),
            onPressed: provider.selectedUrls.isEmpty ? null : () async {
              await provider.validateSelected();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('校驗完成')));
              }
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.output),
            label: const Text('匯出'),
            onPressed: provider.selectedUrls.isEmpty ? null : () async {
              await provider.exportSelected();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已複製至剪貼簿')));
              }
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('刪除', style: TextStyle(color: Colors.red)),
            onPressed: provider.selectedUrls.isEmpty ? null : () async {
              await provider.deleteSelected();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已刪除選定書源')));
              }
            },
          ),
        ],
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
              final provider = context.read<SourceManagerProvider>();
              final input = _importController.text.trim();

              if (input.isNotEmpty) {
                int count;
                if (isUrl) {
                  count = await provider.importFromUrl(input);
                } else {
                  count = await provider.importFromText(input);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(count > 0 ? '成功匯入 $count 個書源' : '匯入失敗')),
                  );
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('匯入'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && context.mounted) {
      final provider = context.read<SourceManagerProvider>();
      final count = await provider.importFromText(data!.text!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(count > 0 ? '從剪貼簿匯入 $count 個書源' : '剪貼簿無有效書源')),
        );
      }
    }
  }
}
