import 'package:flutter/material.dart';
import '../source_manager_provider.dart';

class SourceBatchToolbar extends StatelessWidget {
  final SourceManagerProvider provider;
  final VoidCallback onGroup;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const SourceBatchToolbar({
    super.key,
    required this.provider,
    required this.onGroup,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
            onPressed: provider.selectedUrls.isEmpty ? null : onGroup,
          ),
          TextButton.icon(
            icon: const Icon(Icons.output),
            label: const Text('匯出'),
            onPressed: provider.selectedUrls.isEmpty ? null : onExport,
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('刪除', style: TextStyle(color: Colors.red)),
            onPressed: provider.selectedUrls.isEmpty ? null : onDelete,
          ),
        ],
      ),
    );
  }
}
