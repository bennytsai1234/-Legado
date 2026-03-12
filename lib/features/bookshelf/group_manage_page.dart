import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bookshelf_provider.dart';
import '../../core/database/dao/book_group_dao.dart';
import '../../core/models/book_group.dart';

class GroupManagePage extends StatefulWidget {
  const GroupManagePage({super.key});

  @override
  State<GroupManagePage> createState() => _GroupManagePageState();
}

class _GroupManagePageState extends State<GroupManagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分組管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(context),
          ),
        ],
      ),
      body: Consumer<BookshelfProvider>(
        builder: (context, provider, child) {
          final groups = provider.groups.where((g) => g.groupId > 0).toList();
          
          return ReorderableListView.builder(
            itemCount: groups.length,
            onReorder: (oldIndex, newIndex) {
              // 實作排序邏輯 (Provider 需支援)
              provider.reorderGroups(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                key: ValueKey(group.groupId),
                leading: const Icon(Icons.drag_handle),
                title: Text(group.groupName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(context, group: group),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _showDeleteConfirm(context, provider, group),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, {BookGroup? group}) {
    final controller = TextEditingController(text: group?.groupName ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group == null ? '新建分組' : '編輯分組'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '輸入分組名稱'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final provider = context.read<BookshelfProvider>();
              if (group == null) {
                provider.createGroup(controller.text);
              } else {
                provider.renameGroup(group.groupId, controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, BookshelfProvider provider, BookGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除分組「${group.groupName}」嗎？\n(該分組下的書籍將變更為未分組)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              provider.deleteGroup(group.groupId);
              Navigator.pop(context);
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
