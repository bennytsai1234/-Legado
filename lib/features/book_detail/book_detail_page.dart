import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'book_detail_provider.dart';
import '../../core/models/search_book.dart';
import '../reader/reader_page.dart';
import '../cache_manager/cache_manager_page.dart';

class BookDetailPage extends StatelessWidget {
  final SearchBook searchBook;

  const BookDetailPage({super.key, required this.searchBook});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookDetailProvider(searchBook),
      child: Consumer<BookDetailProvider>(
        builder: (context, provider, child) {
          final book = provider.book;
          return Scaffold(
            appBar: AppBar(
              title: Text(book.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download_for_offline),
                  tooltip: '快取管理',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CacheManagerPage(book: book),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.find_replace),
                  tooltip: '換源',
                  onPressed: () => _showChangeSourceDialog(context, provider),
                ),
                IconButton(
                  icon: Icon(
                    provider.isInBookshelf
                        ? Icons.favorite
                        : Icons.favorite_border,
                  ),
                  color: provider.isInBookshelf ? Colors.red : null,
                  onPressed: provider.toggleBookshelf,
                ),
              ],
            ),
            body:
                provider.isLoading && provider.chapters.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader(context, provider)),
                        SliverToBoxAdapter(child: _buildIntro(book)),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              '目錄 (${provider.chapters.length} 章)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final chapter = provider.chapters[index];
                            return ListTile(
                              title: Text(
                                chapter.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ReaderPage(
                                          book: book,
                                          chapterIndex: index,
                                        ),
                                  ),
                                );
                              },
                            );
                          }, childCount: provider.chapters.length),
                        ),
                      ],
                    ),
            bottomNavigationBar: _buildBottomBar(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BookDetailProvider provider) {
    final book = provider.book;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _showChangeCoverDialog(context, provider),
            child: SizedBox(
              width: 100,
              height: 140,
              child:
                  book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: book.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget:
                            (context, url, error) =>
                                const Icon(Icons.book, size: 50),
                      )
                      : const Icon(Icons.book, size: 50),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '作者：${book.author ?? '未知'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '來源：${book.originName ?? '未知'}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showChangeSourceDialog(context, provider),
                      child: const Text('換源', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                Text(
                  '分類：${book.kind ?? '未知'}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(dynamic book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text(
            '簡介',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            book.intro ?? '暫無簡介',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BookDetailProvider provider) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: provider.toggleBookshelf,
                child: Text(provider.isInBookshelf ? '移出書架' : '加入書架'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ReaderPage(book: provider.book, chapterIndex: 0),
                    ),
                  );
                },
                child: const Text('開始閱讀'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeSourceDialog(BuildContext context, BookDetailProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('換源搜尋', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<SearchBook>>(
                  future: provider.searchAlternativeSources(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('搜尋出錯: ${snapshot.error}'));
                    }
                    final list = snapshot.data ?? [];
                    if (list.isEmpty) {
                      return const Center(child: Text('未找到同名書源'));
                    }
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return ListTile(
                          title: Text(item.originName ?? '未知'),
                          subtitle: Text(item.latestChapterTitle ?? '未知最新章節'),
                          onTap: () {
                            provider.switchSource(item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangeCoverDialog(BuildContext context, BookDetailProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('換封面', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<SearchBook>>(
                  future: provider.searchAlternativeSources(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = snapshot.data?.where((b) => b.coverUrl != null && b.coverUrl!.isNotEmpty).toList() ?? [];
                    if (list.isEmpty) return const Center(child: Text('未找到可用封面'));
                    
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return GestureDetector(
                          onTap: () {
                            provider.updateCover(item.coverUrl!);
                            Navigator.pop(context);
                          },
                          child: CachedNetworkImage(
                            imageUrl: item.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
