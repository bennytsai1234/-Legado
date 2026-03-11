import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/book.dart';
import 'cache_manager_provider.dart';

class CacheManagerPage extends StatelessWidget {
  final Book book;

  const CacheManagerPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CacheManagerProvider(book),
      child: Consumer<CacheManagerProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('${book.name} - 快取管理'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: '清除快取',
                  onPressed: () => _showClearConfirm(context, provider),
                ),
              ],
            ),
            body: Column(
              children: [
                if (provider.downloadService.isDownloading)
                  _buildProgressHeader(provider),
                _buildActionButtons(context, provider),
                const Divider(height: 1),
                Expanded(child: _buildChapterList(provider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader(CacheManagerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withValues(alpha: 0.1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('正在下載中...', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${(provider.downloadService.progress * 100).toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: provider.downloadService.progress),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: provider.downloadService.cancelDownloads,
            child: const Text('停止下載'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CacheManagerProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8,
        children: [
          ElevatedButton(
            onPressed: () => provider.downloadChapters(0, provider.chapters.length),
            child: const Text('下載全部'),
          ),
          ElevatedButton(
            onPressed: () {
              // 下載未快取的章節
              final List<int> unCached = [];
              for (int i = 0; i < provider.chapters.length; i++) {
                if (!provider.cachedIndices.contains(i)) unCached.add(i);
              }
              // 此處簡化為下載全部 (DownloadService 會自動跳過已快取的)
              provider.downloadChapters(0, provider.chapters.length);
            },
            child: const Text('下載未快取'),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList(CacheManagerProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: provider.chapters.length,
      itemBuilder: (context, index) {
        final chapter = provider.chapters[index];
        final isCached = provider.cachedIndices.contains(index);
        return ListTile(
          dense: true,
          title: Text(chapter.title),
          trailing: isCached 
            ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
            : const Icon(Icons.download_for_offline, color: Colors.grey, size: 16),
          onTap: isCached ? null : () => provider.downloadChapters(index, index + 1),
        );
      },
    );
  }

  void _showClearConfirm(BuildContext context, CacheManagerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認清除'),
        content: const Text('確定要清除這本書的所有快取內容嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              provider.clearCache();
              Navigator.pop(context);
            },
            child: const Text('清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
