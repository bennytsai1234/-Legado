import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'explore_provider.dart';
import 'package:legado_reader/features/book_detail/book_detail_page.dart';
import 'package:legado_reader/features/search/search_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String? _expandedSourceUrl;

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
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _showSearchDialog(context, provider),
                ),
                _buildSourcePicker(context, provider),
              ],
            ),
            body: provider.selectedSource == null 
                ? _buildDashboard(provider)
                : _buildFocusedExplore(provider),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(ExploreProvider provider) {
    if (provider.sources.isEmpty) {
      return const Center(child: Text('目前無可用發現規則的書源'));
    }

    return ListView.builder(
      itemCount: provider.sources.length,
      itemBuilder: (context, index) {
        final source = provider.sources[index];
        final isExpanded = _expandedSourceUrl == source.bookSourceUrl;

        return ExpansionTile(
          key: PageStorageKey(source.bookSourceUrl),
          title: Text(source.bookSourceName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(source.bookSourceGroup ?? '未分組', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedSourceUrl = expanded ? source.bookSourceUrl : null;
            });
            if (expanded) {
              provider.setSource(source);
            }
          },
          children: [
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.exploreConfigs.map((config) {
                    return ActionChip(
                      label: Text(config['title'] ?? '', style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        provider.setConfig(config);
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFocusedExplore(ExploreProvider provider) {
    return Column(
      children: [
        _buildExploreHeader(provider),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildExploreResults(provider),
        ),
      ],
    );
  }

  Widget _buildExploreHeader(ExploreProvider provider) {
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      child: Column(
        children: [
          ListTile(
            title: Text(provider.selectedSource!.bookSourceName, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => provider.setSource(null),
            ),
          ),
          _buildExploreConfig(provider),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildExploreConfig(ExploreProvider provider) {
    if (provider.exploreConfigs.isEmpty) return const SizedBox();
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: provider.exploreConfigs.length,
        itemBuilder: (context, index) {
          final config = provider.exploreConfigs[index];
          final isSelected = provider.selectedConfig == config;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(config['title'] ?? ''),
              selected: isSelected,
              onSelected: (val) {
                if (val) provider.setConfig(config);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildExploreResults(ExploreProvider provider) {
    if (provider.books.isEmpty) {
      return const Center(child: Text('暫無內容'));
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: provider.books.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.books.length) {
            provider.loadMore();
            return const Center(child: CircularProgressIndicator());
          }
          final book = provider.books[index];
          return _buildExploreItem(book);
        },
      ),
    );
  }

  Widget _buildExploreItem(SearchBook book) {
    return GestureDetector(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: book.coverUrl ?? '',
                fit: BoxFit.cover,
                width: double.infinity,
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcePicker(BuildContext context, ExploreProvider provider) {
    return IconButton(
      icon: const Icon(Icons.filter_list),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => ListView.builder(
            itemCount: provider.sources.length,
            itemBuilder: (ctx, idx) {
              final s = provider.sources[idx];
              return ListTile(
                title: Text(s.bookSourceName),
                onTap: () {
                  provider.setSource(s);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context, ExploreProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('搜尋發現'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '輸入關鍵字或 group:名稱'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: provider.groups.map((g) => ActionChip(
                label: Text(g, style: const TextStyle(fontSize: 12)),
                onPressed: () {
                  provider.setGroup(g);
                  Navigator.pop(ctx);
                },
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.startsWith('group:')) {
                provider.setGroup(text.replaceFirst('group:', ''));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(initialQuery: text)));
              }
              Navigator.pop(ctx);
            },
            child: const Text('搜尋'),
          ),
        ],
      ),
    );
  }
}
