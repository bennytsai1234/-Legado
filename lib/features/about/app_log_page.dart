import 'package:flutter/material.dart';
import '../../core/services/app_log_service.dart';

class AppLogPage extends StatelessWidget {
  const AppLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('應用程式日誌'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => AppLogService().clearLogs(),
          ),
        ],
      ),
      body: StreamBuilder<List<AppLog>>(
        stream: AppLogService().logStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('目前尚無日誌'));
          }
          final logs = snapshot.data!.reversed.toList();
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                dense: true,
                title: Text(log.message, style: TextStyle(
                  color: _getLogColor(log.level),
                  fontFamily: 'monospace',
                  fontSize: 12,
                )),
                subtitle: Text(log.time, style: const TextStyle(fontSize: 10)),
              );
            },
          );
        },
      ),
    );
  }

  Color _getLogColor(int level) {
    switch (level) {
      case 1: return Colors.blue;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }
}
