import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'explore_provider.dart';
import '../book_detail/book_detail_page.dart';
import '../../core/models/search_book.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('發現'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ExploreProvider>().loadExploreData(),
          ),
        ],
      ),
      body: Consumer<ExploreProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.exploreMap.isEmpty) {
            return const Center(child: Text('暫無可用發現頁的書源'));
          }
          
          final sourceNames = provider.exploreMap.keys.toList();
          return ListView.builder(
            itemCount: sourceNames.length,
            itemBuilder: (context, index) {
              final sourceName = sourceNames[index];
              final items = provider.exploreMap[sourceName]!;
              return _buildSourceSection(context, sourceName, items);
            },
          );
        },
      ),
    );
  }

  Widget _buildSourceSection(BuildContext context, String sourceName, List<ExploreItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            sourceName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 0,
            children: items.map((item) => ActionChip(
              label: Text(item.title),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryResultPage(item: item),
                  ),
                );
              },
            )).toList(),
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class CategoryResultPage extends StatefulWidget {
  final ExploreItem item;
  const CategoryResultPage({super.key, required this.item});

  @override
  State<CategoryResultPage> createState() => _CategoryResultPageState();
}

class _CategoryResultPageState extends State<CategoryResultPage> {
  final List<SearchBook> _books = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    final provider = context.read<ExploreProvider>();
    final newBooks = await provider.loadCategoryBooks(widget.item, _currentPage);
    
    if (mounted) {
      setState(() {
        if (newBooks.isEmpty) {
          _hasMore = false;
        } else {
          _books.addAll(newBooks);
          _currentPage++;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.title)),
      body: _books.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              controller: _scrollController,
              itemCount: _books.length + (_hasMore ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == _books.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final book = _books[index];
                return ListTile(
                  leading: SizedBox(
                    width: 45,
                    height: 60,
                    child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(Icons.book),
                          )
                        : const Icon(Icons.book),
                  ),
                  title: Text(book.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(book.author ?? '未知作者'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailPage(searchBook: book),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
