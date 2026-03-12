import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'explore_provider.dart';
import '../book_detail/book_detail_page.dart';
import '../../core/models/book_source.dart';
import '../../core/models/search_book.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExploreProvider(),
      child: Consumer<ExploreProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('發現'),
              actions: [
                _buildSourcePicker(context, provider),
              ],
            ),
            body: Column(
              children: [
                if (provider.selectedSource != null)
                  _buildExploreConfig(provider),
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildExploreResults(provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSourcePicker(BuildContext context, ExploreProvider provider) {
    return PopupMenuButton<BookSource>(
      icon: const Icon(Icons.filter_list),
      tooltip: '選擇書源',
      onSelected: provider.setSource,
      itemBuilder: (context) {
        return provider.sources.map((source) {
          return PopupMenuItem(
            value: source,
            child: Text(source.bookSourceName),
          );
        }).toList();
      },
    );
  }

  Widget _buildExploreConfig(ExploreProvider provider) {
    if (provider.exploreConfigs.isEmpty) return const SizedBox();
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.exploreConfigs.length,
        itemBuilder: (context, index) {
          final config = provider.exploreConfigs[index];
          final isSelected = provider.selectedConfig == config;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(config['title'] ?? ''),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) provider.setConfig(config);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildExploreResults(ExploreProvider provider) {
    if (provider.books.isEmpty) {
      return const Center(child: Text('請選擇書源開始探索'));
    }
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.builder(
        itemCount: provider.books.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.books.length) {
            provider.loadMore();
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final book = provider.books[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: book.coverUrl!,
                      width: 45,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.book),
                    )
                  : const Icon(Icons.book, size: 45),
            ),
            title: Text(book.name),
            subtitle: Text('${book.author ?? '未知'} · ${book.kind ?? ''}'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailPage(
                    searchBook: AggregatedSearchBook(
                      book: book,
                      sources: [book.originName ?? '發現'],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
