import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/engine/analyze_rule.dart';
import '../../shared/widgets/base_scaffold.dart';

/// DebugPage - 規則調試頁面
/// 對應 Android: ui/book/source/debug/DebugActivity.kt
class DebugPage extends StatefulWidget {
  final String title;
  const DebugPage({super.key, required this.title});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _logSub;

  @override
  void initState() {
    super.initState();
    _initLogs();
  }

  void _initLogs() {
    AnalyzeRule.debugLogController ??= StreamController<String>.broadcast();
    _logSub = AnalyzeRule.debugLogController!.stream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _logSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: '調試: ${widget.title}',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          tooltip: '清空日誌',
          onPressed: () => setState(() => _logs.clear()),
        ),
      ],
      body: Container(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.grey[50],
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            final log = _logs[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: SelectableText(
                log,
                style: TextStyle(
                  fontFamily: 'Courier', // 模擬終端字體
                  fontSize: 13,
                  fontWeight: log.startsWith('⇒') ? FontWeight.bold : FontWeight.normal,
                  color: _getLogColor(context, log),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getLogColor(BuildContext context, String log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (log.startsWith('⇒')) return isDark ? Colors.lightBlueAccent : Colors.blue[800]!;
    if (log.contains('✕') || log.contains('Error') || log.contains('失敗')) return Colors.red;
    if (log.contains('✓') || log.contains('成功')) return Colors.green;
    if (log.startsWith('  ◇')) return isDark ? Colors.orangeAccent : Colors.orange[800]!;
    if (log.startsWith('  └')) return isDark ? Colors.white70 : Colors.black54;
    return isDark ? Colors.white : Colors.black87;
  }
}
