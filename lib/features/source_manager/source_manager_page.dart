import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:legado_reader/features/source_manager/source_manager_provider.dart';
import 'package:legado_reader/features/source_manager/source_editor_page.dart';
import 'package:legado_reader/features/source_manager/qr_scan_page.dart';
import 'package:legado_reader/features/source_manager/explore_sources_page.dart';
import 'package:legado_reader/features/source_manager/source_debug_page.dart';
import 'package:legado_reader/features/source_manager/source_group_manage_page.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/features/source_manager/widgets/source_item_tile.dart';
import 'package:legado_reader/features/source_manager/widgets/source_filter_bar.dart';
import 'package:legado_reader/features/source_manager/widgets/source_batch_toolbar.dart';

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
            title: Text(provider.isBatchMode ? '已選擇 ${provider.selectedUrls.length} 項' : '書源管理'),
            actions: provider.isBatchMode
                ? [
                    IconButton(icon: const Icon(Icons.select_all), onPressed: provider.selectAll),
                    IconButton(icon: const Icon(Icons.close), onPressed: provider.toggleBatchMode),
                  ]
                : [
                    IconButton(icon: const Icon(Icons.refresh), onPressed: provider.loadSources),
                    _buildAddMenu(context, provider),
                    _buildMoreMenu(context, provider),
                  ],
          ),
          body: Column(
            children: [
              if (provider.checkService.isChecking) _buildCheckStatusBar(context, provider),
              if (!provider.isBatchMode) SourceFilterBar(provider: provider),
              Expanded(child: _buildSourceList(provider)),
            ],
          ),
          bottomNavigationBar: provider.isBatchMode 
            ? SourceBatchToolbar(
                provider: provider,
                onGroup: () => _showBatchGroupDialog(context, provider),
                onExport: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await provider.exportSelected();
                  if (!mounted) return;
                  messenger.showSnackBar(const SnackBar(content: Text('已複製至剪貼簿')));
                },
                onDelete: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await provider.deleteSelected();
                  if (!mounted) return;
                  messenger.showSnackBar(const SnackBar(content: Text('已刪除選定書源')));
                },
              ) 
            : null,
        );
      },
    );
  }

  Widget _buildCheckStatusBar(BuildContext context, SourceManagerProvider provider) {
    return GestureDetector(
      onTap: () => _showCheckLogDialog(context, provider),
      child: Container(
        color: Colors.blue.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Expanded(child: Text('正在校驗 (${provider.checkService.currentCount}/${provider.checkService.totalCount}): ${provider.checkService.statusMsg}', style: const TextStyle(fontSize: 12))),
            const Icon(Icons.chevron_right, size: 16, color: Colors.blue),
            TextButton(onPressed: provider.checkService.cancel, child: const Text('取消')),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceList(SourceManagerProvider provider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (provider.sources.isEmpty) return const Center(child: Text('暫無書源'));

    final bool canReorder = provider.sortMode == 0 && !provider.groupByDomain;

    if (canReorder) {
      return ReorderableListView.builder(
        itemCount: provider.sources.length,
        onReorder: provider.reorderSource,
        itemBuilder: (context, index) => _buildItem(provider, provider.sources[index]),
      );
    }

    return ListView.separated(
      itemCount: provider.sources.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildItem(provider, provider.sources[index]),
    );
  }

  Widget _buildItem(SourceManagerProvider provider, BookSource source) {
    return SourceItemTile(
      key: ValueKey(source.bookSourceUrl),
      source: source,
      provider: provider,
      isSelected: provider.selectedUrls.contains(source.bookSourceUrl),
      onTap: () {
        if (provider.isBatchMode) {
          provider.toggleSelect(source.bookSourceUrl);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SourceEditorPage(source: source)));
        }
      },
      onLongPress: () { if (!provider.isBatchMode) _showSourceMenu(context, provider, source); },
      onEnabledChanged: (v) => provider.toggleEnabled(source),
    );
  }

  Widget _buildAddMenu(BuildContext context, SourceManagerProvider provider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add),
      onSelected: (value) {
        switch(value) {
          case 'url': _showImportDialog(context, isUrl: true); break;
          case 'file': _importFromFile(context); break;
          case 'clipboard': _importFromClipboard(context); break;
          case 'qr': _scanQrCode(context, provider); break;
          case 'explore': Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreSourcesPage())); break;
          case 'manage_groups': Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceGroupManagePage())); break;
          case 'new': Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceEditorPage())); break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'url', child: Text('網路匯入')),
        const PopupMenuItem(value: 'file', child: Text('本地匯入')),
        const PopupMenuItem(value: 'clipboard', child: Text('剪貼簿匯入')),
        const PopupMenuItem(value: 'qr', child: Text('掃碼匯入')),
        const PopupMenuItem(value: 'explore', child: Text('網路書源庫搜尋')),
        const PopupMenuItem(value: 'manage_groups', child: Text('管理分組')),
        const PopupMenuItem(value: 'new', child: Text('新建書源')),
      ],
    );
  }

  Widget _buildMoreMenu(BuildContext context, SourceManagerProvider provider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'group_by_domain') { provider.toggleGroupByDomain(); }
        else if (value.startsWith('sort_')) { provider.setSortMode(int.parse(value.substring(5))); }
        else if (value == 'check_all') { provider.checkAllSources(); }
        else if (value == 'clear_invalid') { _confirmClearInvalid(context, provider); }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'group_by_domain', child: Row(children: [Icon(provider.groupByDomain ? Icons.check_box : Icons.check_box_outline_blank, size: 20), const SizedBox(width: 10), const Text('按域名分組')])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'sort_0', child: Text('手動排序')),
        const PopupMenuItem(value: 'sort_1', child: Text('權重排序')),
        const PopupMenuItem(value: 'check_all', child: Text('校驗所有書源')),
        const PopupMenuItem(value: 'clear_invalid', child: Text('清理失效書源', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  void _showSourceMenu(BuildContext context, SourceManagerProvider provider, BookSource source) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.bug_report), title: const Text('調試書源'), onTap: () { Navigator.pop(context); _showDebugInputDialog(context, source); }),
            ListTile(leading: const Icon(Icons.edit), title: const Text('編輯書源'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => SourceEditorPage(source: source))); }),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('刪除書源', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); provider.deleteSource(source); }),
          ],
        ),
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
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(provider.checkService.statusMsg, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'), textAlign: TextAlign.center),
                ],
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉', style: TextStyle(color: Colors.white)))],
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
            TextField(controller: controller, decoration: const InputDecoration(hintText: '輸入或選擇分組名')),
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
                  return ListTile(title: Text(g), dense: true, onTap: () => controller.text = g);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () { provider.selectionRemoveFromGroups(provider.selectedUrls, controller.text.trim()); Navigator.pop(context); }, child: const Text('移除分組')),
          ElevatedButton(onPressed: () { provider.selectionAddToGroups(provider.selectedUrls, controller.text.trim()); Navigator.pop(context); }, child: const Text('加入分組')),
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
          TextButton(onPressed: () { provider.clearInvalidSources(); Navigator.pop(context); }, child: const Text('確定刪除', style: TextStyle(color: Colors.red))),
        ],
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
            const Text('支援: 搜尋詞, URL, ::發現, ++目錄, --正文', style: TextStyle(fontSize: 12, color: Colors.grey)),
            TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: '搜尋詞或 URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => SourceDebugPage(source: source, debugKey: controller.text.trim()))); }, child: const Text('開始調試')),
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
        content: TextField(controller: _importController, decoration: InputDecoration(hintText: isUrl ? '請輸入書源 URL (可換行多個)' : '請貼上書源 JSON'), maxLines: 5),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(onPressed: () async {
            final provider = context.read<SourceManagerProvider>();
            final input = _importController.text.trim();
            if (input.isNotEmpty) {
              int count = isUrl ? await provider.importFromUrl(input) : await provider.importFromText(input);
              if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(count > 0 ? '成功匯入 $count 個書源' : '匯入失敗'))); Navigator.pop(context); }
            } else { Navigator.pop(context); }
          }, child: const Text('匯入')),
        ],
      ),
    );
  }

  Future<void> _scanQrCode(BuildContext context, SourceManagerProvider provider) async {
    final String? result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScanPage()));
    if (result != null && result.isNotEmpty && context.mounted) {
      final count = await provider.importFromQr(result);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(count > 0 ? '成功匯入 $count 個書源' : '未找到有效書源')));
    }
  }

  Future<void> _importFromFile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json', 'txt']);
      if (result != null && result.files.single.path != null && mounted) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final count = await context.read<SourceManagerProvider>().importFromText(content);
        messenger.showSnackBar(SnackBar(content: Text(count > 0 ? '從檔案匯入 $count 個書源' : '檔案無有效書源')));
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('選取檔案出錯: $e')));
    }
  }

  Future<void> _importFromClipboard(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      final count = await context.read<SourceManagerProvider>().importFromText(data!.text!);
      messenger.showSnackBar(SnackBar(content: Text(count > 0 ? '從剪貼簿匯入 $count 個書源' : '剪貼簿無有效書源')));
    }
  }
}
