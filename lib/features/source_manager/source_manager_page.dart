import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'source_manager_provider.dart';
import 'source_editor_page.dart';
import 'qr_scan_page.dart';
import 'explore_sources_page.dart';
import 'source_group_manage_page.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'widgets/source_item_tile.dart';
import 'widgets/source_filter_bar.dart';
import 'widgets/source_batch_toolbar.dart';
import 'widgets/source_check_status_bar.dart';
import 'widgets/source_manager_menus.dart';
import 'widgets/source_manager_dialogs.dart';

class SourceManagerPage extends StatefulWidget {
  const SourceManagerPage({super.key});
  @override State<SourceManagerPage> createState() => _SourceManagerPageState();
}

class _SourceManagerPageState extends State<SourceManagerPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SourceManagerProvider>(builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text(provider.isBatchMode ? '已選擇 ${provider.selectedUrls.length} 項' : '書源管理'),
          actions: provider.isBatchMode ? [
            IconButton(icon: const Icon(Icons.select_all), onPressed: provider.selectAll),
            IconButton(icon: const Icon(Icons.close), onPressed: provider.toggleBatchMode),
          ] : [
            IconButton(icon: const Icon(Icons.refresh), onPressed: provider.loadSources),
            SourceManagerMenus.buildAddMenu(context, provider, 
              onImportUrl: () => _showImportDialog(context, true), onImportFile: () => _importFromFile(context), 
              onImportClipboard: () => _importFromClipboard(context), onScanQr: () => _scanQrCode(context, provider), 
              onExplore: () { if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const ExploreSourcesPage())); }, 
              onManageGroups: () { if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceGroupManagePage())); }, 
              onNewSource: () { if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceEditorPage())); }),
            SourceManagerMenus.buildMoreMenu(context, provider, onClearInvalid: (p) => SourceManagerDialogs.confirmClearInvalid(context, p)),
          ],
        ),
        body: Column(children: [
          if (provider.checkService.isChecking) SourceCheckStatusBar(provider: provider, onTap: () => SourceManagerDialogs.showCheckLog(context, provider)),
          if (!provider.isBatchMode) SourceFilterBar(provider: provider),
          Expanded(child: _buildSourceList(provider)),
        ]),
        bottomNavigationBar: provider.isBatchMode ? SourceBatchToolbar(provider: provider, onGroup: () => SourceManagerDialogs.showBatchGroup(context, provider), 
          onExport: () async { await provider.exportSelected(); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已複製至剪貼簿'))); } }, 
          onDelete: () async { await provider.deleteSelected(); if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已刪除選定書源'))); } }) : null,
      );
    });
  }

  Widget _buildSourceList(SourceManagerProvider p) {
    if (p.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.sources.isEmpty) {
      return const Center(child: Text('暫無書源'));
    }
    final bool canReorder = p.sortMode == 0 && !p.groupByDomain;
    if (canReorder) {
      return ReorderableListView.builder(itemCount: p.sources.length, onReorder: p.reorderSource, itemBuilder: (ctx, i) => _buildItem(p, p.sources[i]));
    } else {
      return ListView.separated(itemCount: p.sources.length, separatorBuilder: (ctx, i) => const Divider(height: 1), itemBuilder: (ctx, i) => _buildItem(p, p.sources[i]));
    }
  }

  Widget _buildItem(SourceManagerProvider p, BookSource s) => SourceItemTile(key: ValueKey(s.bookSourceUrl), source: s, provider: p, isSelected: p.selectedUrls.contains(s.bookSourceUrl), 
    onTap: () { if (p.isBatchMode) { p.toggleSelect(s.bookSourceUrl); } else { if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => SourceEditorPage(source: s))); } }, 
    onLongPress: () { if (!p.isBatchMode) { _showSourceMenu(context, p, s); } }, onEnabledChanged: (v) => p.toggleEnabled(s));

  void _showSourceMenu(BuildContext context, SourceManagerProvider p, BookSource s) {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.bug_report), title: const Text('調試書源'), onTap: () { Navigator.pop(ctx); SourceManagerDialogs.showDebugInput(context, s); }),
      ListTile(leading: const Icon(Icons.edit), title: const Text('編輯書源'), onTap: () { Navigator.pop(ctx); if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => SourceEditorPage(source: s))); }),
      ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('刪除書源', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(ctx); p.deleteSource(s); }),
    ])));
  }

  void _showImportDialog(BuildContext context, bool isUrl) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(isUrl ? '網路匯入' : '文本匯入'), content: TextField(controller: ctrl, decoration: InputDecoration(hintText: isUrl ? '請輸入 URL' : '請貼上 JSON'), maxLines: 5), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      ElevatedButton(onPressed: () async {
        final p = context.read<SourceManagerProvider>();
        final input = ctrl.text.trim();
        if (input.isNotEmpty) {
          int count = isUrl ? await p.importFromUrl(input) : await p.importFromText(input);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功匯入 $count 個書源')));
            Navigator.pop(ctx);
          }
        } else {
          Navigator.pop(ctx);
        }
      }, child: const Text('匯入')),
    ]));
  }

  Future<void> _scanQrCode(BuildContext context, SourceManagerProvider p) async {
    final String? res = await Navigator.push(context, MaterialPageRoute(builder: (ctx) => const QrScanPage()));
    if (res != null && res.isNotEmpty) {
      final count = await p.importFromQr(res);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功匯入 $count 個書源')));
      }
    }
  }

  Future<void> _importFromFile(BuildContext context) async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json', 'txt']);
      if (res?.files.single.path != null) {
        final p = context.read<SourceManagerProvider>();
        final count = await p.importFromText(await File(res!.files.single.path!).readAsString());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('從檔案匯入 $count 個書源')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('出錯: $e')));
      }
    }
  }

  Future<void> _importFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final p = context.read<SourceManagerProvider>();
      final count = await p.importFromText(data!.text!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('從剪貼簿匯入 $count 個書源')));
      }
    }
  }
}
