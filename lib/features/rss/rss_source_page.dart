import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'rss_source_provider.dart';

class RssSourcePage extends StatelessWidget {
  const RssSourcePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訂閱管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新載入',
            onPressed: () => context.read<RssSourceProvider>().loadSources(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新增訂閱',
            onPressed: () {
              // TODO: 新增 RSS 書源
            },
          ),
        ],
      ),
      body: Consumer<RssSourceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.sources.isEmpty) {
            return const Center(child: Text('暫無訂閱源'));
          }
          return ListView.builder(
            itemCount: provider.sources.length,
            itemBuilder: (context, index) {
              final source = provider.sources[index];
              return Dismissible(
                key: Key(source.sourceUrl),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  provider.deleteSource(source);
                },
                child: ListTile(
                  leading: const Icon(Icons.rss_feed, color: Colors.orange),
                  title: Text(source.sourceName.isNotEmpty ? source.sourceName : "未命名來源"),
                  subtitle: Text(
                    source.sourceUrl, 
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Switch(
                    value: source.enabled,
                    onChanged: (v) => provider.toggleEnabled(source),
                  ),
                  onTap: () {
                    // TODO: 進入閱讀文章列表
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
