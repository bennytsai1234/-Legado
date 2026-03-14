import 'package:flutter/material.dart';
import '../source_manager_provider.dart';

class SourceManagerMenus {
  static Widget buildAddMenu(BuildContext context, SourceManagerProvider provider, {
    required Function() onImportUrl,
    required Function() onImportFile,
    required Function() onImportClipboard,
    required Function() onScanQr,
    required Function() onExplore,
    required Function() onManageGroups,
    required Function() onNewSource,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add),
      onSelected: (value) {
        switch(value) {
          case 'url': onImportUrl(); break;
          case 'file': onImportFile(); break;
          case 'clipboard': onImportClipboard(); break;
          case 'qr': onScanQr(); break;
          case 'explore': onExplore(); break;
          case 'manage_groups': onManageGroups(); break;
          case 'new': onNewSource(); break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'url', child: Text('網路匯入')),
        const PopupMenuItem(value: 'file', child: Text('本地匯入')),
        const PopupMenuItem(value: 'clipboard', child: Text('剪貼簿匯入')),
        const PopupMenuItem(value: 'qr', child: Text('掃碼匯入')),
        const PopupMenuItem(value: 'explore', child: Text('網路書源庫')),
        const PopupMenuItem(value: 'manage_groups', child: Text('管理分組')),
        const PopupMenuItem(value: 'new', child: Text('新建書源')),
      ],
    );
  }

  static Widget buildMoreMenu(BuildContext context, SourceManagerProvider provider, {required Function(SourceManagerProvider) onClearInvalid}) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'group_by_domain') {
          provider.toggleGroupByDomain();
        } else if (value.startsWith('sort_')) provider.setSortMode(int.parse(value.substring(5)));
        else if (value == 'check_all') provider.checkAllSources();
        else if (value == 'clear_invalid') onClearInvalid(provider);
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'group_by_domain', child: Row(children: [Icon(provider.groupByDomain ? Icons.check_box : Icons.check_box_outline_blank, size: 20), const SizedBox(width: 10), const Text('按域名分組')])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'sort_0', child: Text('手動排序')),
        const PopupMenuItem(value: 'sort_1', child: Text('權重排序')),
        const PopupMenuItem(value: 'check_all', child: Text('校驗所有')),
        const PopupMenuItem(value: 'clear_invalid', child: Text('清理失效', style: TextStyle(color: Colors.red))),
      ],
    );
  }
}
