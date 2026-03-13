import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/engine/analyze_rule.dart';
import '../../core/models/book_source.dart';
import '../../shared/widgets/base_scaffold.dart';

/// DebugPage - 規則調試頁面
/// 對應 Android: ui/book/source/debug/DebugActivity.kt
class DebugPage extends StatefulWidget {
  final BookSource source;
  const DebugPage({super.key, required this.source});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription? _logSub;
  bool _isDebugging = false;

  @override
  void initState() {
    super.initState();
    _initLogs();
    _searchController.text = widget.source.ruleSearch?.checkKeyWord ?? '我的';
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

  void _startDebug(String key) async {
    if (_isDebugging) return;
    setState(() {
      _isDebugging = true;
      _logs.clear();
      _logs.add('⇒ 開始偵錯: $key');
    });

    try {
      // TODO: 實作偵錯流程調用
      // 目前僅模擬日誌
      await Future.delayed(const Duration(seconds: 1));
      AnalyzeRule.debugLogController?.add('✓ 偵錯功能待完全補齊');
    } finally {
      if (mounted) setState(() => _isDebugging = false);
    }
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: '調試: ${widget.source.bookSourceName}',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          tooltip: '清空日誌',
          onPressed: () => setState(() => _logs.clear()),
        ),
      ],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '搜尋關鍵字或 URL',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _startDebug,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isDebugging ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow),
                  onPressed: () => _startDebug(_searchController.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
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
          ),
        ],
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
