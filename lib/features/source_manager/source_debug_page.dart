import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/book_source.dart';
import 'source_debug_provider.dart';

class SourceDebugPage extends StatefulWidget {
  final BookSource source;
  final String debugKey;

  const SourceDebugPage({
    super.key,
    required this.source,
    required this.debugKey,
  });

  @override
  State<SourceDebugPage> createState() => _SourceDebugPageState();
}

class _SourceDebugPageState extends State<SourceDebugPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = SourceDebugProvider(widget.source, widget.debugKey);
        // 在下一幀啟動調試，避免 build 衝突
        WidgetsBinding.instance.addPostFrameCallback((_) => provider.startDebug());
        return provider;
      },
      child: Consumer<SourceDebugProvider>(
        builder: (context, provider, child) {
          // 當日誌更新時自動滾動到底部
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

          return Scaffold(
            appBar: AppBar(
              title: Text('調試: ${widget.source.bookSourceName}'),
              actions: [
                if (!provider.isFinished)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: provider.isFinished ? () => provider.startDebug() : null,
                ),
              ],
            ),
            body: Container(
              color: Colors.black87,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: provider.logs.length,
                itemBuilder: (context, index) {
                  final log = provider.logs[index];
                  Color textColor = Colors.white;
                  
                  if (log.state == -1) {
                    textColor = Colors.redAccent;
                  } else if (log.state == 1000) {
                    textColor = Colors.greenAccent;
                  } else if (log.state >= 10 && log.state <= 40) {
                    textColor = Colors.lightBlueAccent;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${log.formattedTime} ',
                            style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace'),
                          ),
                          TextSpan(
                            text: log.message,
                            style: TextStyle(color: textColor, fontSize: 13, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
