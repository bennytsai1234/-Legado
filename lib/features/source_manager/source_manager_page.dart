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
import 'source_debug_page.dart';
import 'source_group_manage_page.dart';
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
                        } else if (value == 'manage_groups') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SourceGroupManagePage(),
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
                        const PopupMenuItem(value: 'manage_groups', child: Text('管理分組')),
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
                        } else if (value == 'check_all') {
                          provider.checkAllSources();
                        } else if (value == 'clear_invalid') {
                          _confirmClearInvalid(context, provider);
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
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'check_all', child: Text('校驗所有書源')),
                        const PopupMenuItem(value: 'clear_invalid', child: Text('清理失效書源', style: TextStyle(color: Colors.red))),
                      ],
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
          ),
          body: Column(
            children: [
              if (provider.checkService.isChecking)
                GestureDetector(
                  onTap: () => _showCheckLogDialog(context, provider),
                  child: Container(
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
                        const Icon(Icons.chevron_right, size: 16, color: Colors.blue),
                        TextButton(onPressed: provider.checkService.cancel, child: const Text('取消')),
                      ],
                    ),
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

        final bool canReorder = provider.sortMode == 0 && !provider.groupByDomain;

        if (canReorder) {
          return ReorderableListView.builder(
            itemCount: provider.sources.length,
            onReorder: provider.reorderSource,
            itemBuilder: (context, index) {
              final source = provider.sources[index];
              return _buildSourceItem(context, provider, source, key: ValueKey(source.bookSourceUrl));
            },
          );
        }

        return ListView.separated(
          itemCount: provider.sources.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final source = provider.sources[index];
            return _buildSourceItem(context, provider, source, key: ValueKey(source.bookSourceUrl));
          },
        );
      },
    );
  }

  Widget _buildSourceItem(
      BuildContext context, SourceManagerProvider provider, BookSource source, {required Key key}) {
    bool isSelected = provider.selectedUrls.contains(source.bookSourceUrl);
    
    String statusStr = "未校驗";
    Color statusColor = Colors.grey;

    if (source.respondTime > 0) {
      statusStr = "${source.respondTime}ms";
      statusColor = source.respondTime < 1000 ? Colors.green : Colors.orange;
    } else if (source.respondTime == -1) {
      statusStr = "失效";
      statusColor = Colors.red;
    }

    final tile = ListTile(
      key: key,
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
          _showSourceMenu(context, provider, source);
        }
      },
    );

    if (provider.isBatchMode) return tile;

    return Dismissible(
      key: key,
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

  void _showSourceMenu(BuildContext context, SourceManagerProvider provider, BookSource source) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('調試書源'),
              onTap: () {
                Navigator.pop(context);
                _showDebugInputDialog(context, source);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('編輯書源'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SourceEditorPage(source: source)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.select_all),
              title: const Text('批次模式'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleBatchMode();
                provider.toggleSelect(source.bookSourceUrl);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('刪除書源', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                provider.deleteSource(source);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDebugInputDialog(BuildContext context, BookSource source) {
    final controller = TextEditingController(text: '我的世界');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('輸入調試關鍵字'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '支援: 搜尋詞, URL, ::發現, ++目錄, --正文',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: '搜尋詞或 URL'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SourceDebugPage(
                    source: source,
                    debugKey: controller.text.trim(),
                  ),
                ),
              );
            },
            child: const Text('開始調試'),
          ),
        ],
      ),
    );
  }

  void _showBatchGroupDialog(BuildContext context, SourceManagerProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量管理分組'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '輸入或選擇分組名'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.groups.length,
                itemBuilder: (context, index) {
                  final g = provider.groups[index];
                  if (g == '全部' || g == '未分組') return const SizedBox.shrink();
                  return ListTile(
                    title: Text(g),
                    dense: true,
                    onTap: () => controller.text = g,
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.selectionRemoveFromGroups(provider.selectedUrls, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('移除分組'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.selectionAddToGroups(provider.selectedUrls, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('加入分組'),
          ),
        ],
      ),
    );
  }

  void _confirmClearInvalid(BuildContext context, SourceManagerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理失效書源'),
        content: const Text('確定要刪除所有標記為「失效」或「搜尋失效」的書源嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              provider.clearInvalidSources();
              Navigator.pop(context);
            },
            child: const Text('確定刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCheckLogDialog(BuildContext context, SourceManagerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('校驗詳情'),
        backgroundColor: Colors.black87,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder(
            stream: provider.checkService.eventBus.on(),
            builder: (context, snapshot) {
              // 注意：這裡需要一個能緩存日誌的機制，
              // 為了簡化，目前僅顯示最後一條或提示使用者
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    provider.checkService.statusMsg,
                    style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('分組'),
            onPressed: provider.selectedUrls.isEmpty ? null : () => _showBatchGroupDialog(context, provider),
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
      final count = await provider.importFromQr(result);
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
