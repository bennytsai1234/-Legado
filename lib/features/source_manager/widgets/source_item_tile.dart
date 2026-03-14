import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/features/source_manager/source_manager_provider.dart';
import 'package:legado_reader/features/source_manager/source_login_page.dart';

class SourceItemTile extends StatelessWidget {
  final BookSource source;
  final SourceManagerProvider provider;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(bool) onEnabledChanged;

  const SourceItemTile({
    super.key,
    required this.source,
    required this.provider,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onEnabledChanged,
  });

  @override
  Widget build(BuildContext context) {
    String statusStr = "未校驗";
    Color statusColor = Colors.grey;

    if (source.respondTime > 0) {
      statusStr = "${source.respondTime}ms";
      statusColor = source.respondTime < 1000 ? Colors.green : Colors.orange;
    } else if (source.respondTime == -1) {
      statusStr = "失效";
      statusColor = Colors.red;
    }

    return ListTile(
      leading: provider.isBatchMode
          ? Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? Colors.blue : Colors.grey,
            )
          : null,
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
                if (source.loginUrl?.isNotEmpty == true)
                  IconButton(
                    icon: const Icon(Icons.login, size: 20),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SourceLoginPage(source: source)),
                    ),
                  ),
                Switch(
                  value: source.enabled,
                  onChanged: onEnabledChanged,
                ),
              ],
            ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
