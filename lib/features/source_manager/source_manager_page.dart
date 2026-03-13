import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'source_manager_provider.dart';
import 'source_editor_page.dart';
import 'source_login_page.dart';
import 'qr_scan_page.dart';
import 'explore_sources_page.dart';
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
                      icon: const Icon(Icons.format_line_spacing),
                      tooltip: '區間選擇',
                      onPressed: provider.selectedUrls.length >= 2 ? provider.selectInterval : null,
                      ),
                      IconButton(
                      icon: const Icon(Icons.close),                      tooltip: '取消',
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
                        } else if (value == 'file') {
                          _importFromFile(context);
                        } else if (value == 'clipboard') {
                          _importFromClipboard(context);
                        } else if (value == 'qr') {
                          _scanQrCode(context, provider);
                        } else if (value == 'new') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SourceEditorPage(),
                            ),
                          );
                        } else if (value == 'explore') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExploreSourcesPage(),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'url', child: Text('網路匯入')),
                        const PopupMenuItem(value: 'file', child: Text('本地匯入')),
                        const PopupMenuItem(
                            value: 'clipboard', child: Text('剪貼簿匯入')),
                        const PopupMenuItem(value: 'qr', child: Text('掃碼匯入')),
                        const PopupMenuItem(value: 'explore', child: Text('網路書源庫搜尋')),
                        const PopupMenuItem(value: 'new', child: Text('新建書源')),
                      ],
                      icon: const Icon(Icons.add),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'group_by_domain') {
                          provider.toggleGroupByDomain();
                        } else if (value.startsWith('sort_')) {
                          provider.setSortMode(int.parse(value.substring(5)));
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'group_by_domain',
                          child: Row(
                            children: [
                              Icon(provider.groupByDomain ? Icons.check_box : Icons.check_box_outline_blank, size: 20),
                              const SizedBox(width: 10),
                              const Text('按域名分組'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'sort_0', child: Text('手動排序')),
                        const PopupMenuItem(value: 'sort_1', child: Text('權重排序')),
                        const PopupMenuItem(value: 'sort_2', child: Text('響應速度排序')),
                        const PopupMenuItem(value: 'sort_3', child: Text('更新時間排序')),
                        const PopupMenuItem(value: 'sort_4', child: Text('名稱排序')),
                      ],
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
          ),
          body: Column(
            children: [
              if (provider.checkService.isChecking)
                Container(
                  color: Colors.blue.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '正在校驗 (${provider.checkService.currentCount}/${provider.checkService.totalCount}): ${provider.checkService.statusMsg}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton(onPressed: provider.checkService.cancel, child: const Text('取消')),
                    ],
                  ),
                ),
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
    
    // 判斷狀態 (高度還原 Android 顯示)
    String statusStr = "未校驗";
    Color statusColor = Colors.grey;

    if (source.respondTime > 0) {
      statusStr = "${source.respondTime}ms";
      statusColor = source.respondTime < 1000 ? Colors.green : Colors.orange;
    } else if (source.respondTime == -1) {
      statusStr = "失效";
      statusColor = Colors.red;
    }

    if (source.bookSourceGroup?.contains("搜尋失效") ?? false) {
      statusStr = "搜尋失效";
      statusColor = Colors.red;
    } else if (source.bookSourceGroup?.contains("校驗超時") ?? false) {
      statusStr = "超時";
      statusColor = Colors.orange;
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
      trailing: provider.isBatchMode
          ? null
          : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (source.loginUrl != null && source.loginUrl!.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.login, size: 20),
                  tooltip: '登入',
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SourceLoginPage(source: source),
                        ),
                      ),
                ),
              Switch(
                value: source.enabled,
                onChanged: (value) => provider.toggleEnabled(source),
              ),
            ],
          ),
      onTap: () {
        if (provider.isBatchMode) {
          provider.toggleSelect(source.bookSourceUrl);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SourceEditorPage(source: source),
            ),
          );
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
            icon: const Icon(Icons.playlist_add_check),
            label: const Text('校驗'),
            onPressed: provider.selectedUrls.isEmpty ? null : () => provider.checkSelectedSources(),
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
            hintText: isUrl ? '請輸入書源 URL (可換行多個)' : '請貼上書源 JSON',
          ),
          maxLines: 5,
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

  Future<void> _scanQrCode(BuildContext context, SourceManagerProvider provider) async {
    final String? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScanPage()),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      int count = 0;
      if (result.startsWith('http')) {
        count = await provider.importFromUrl(result);
      } else {
        count = await provider.importFromText(result);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(count > 0 ? '成功匯入 $count 個書源' : '未找到有效書源')),
      );
    }
  }

  Future<void> _importFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (result != null && result.files.single.path != null && context.mounted) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        if (!context.mounted) return;
        final provider = context.read<SourceManagerProvider>();
        final count = await provider.importFromText(content);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(count > 0 ? '從檔案匯入 $count 個書源' : '檔案無有效書源')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('選取檔案出錯: $e')),
        );
      }
    }
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
