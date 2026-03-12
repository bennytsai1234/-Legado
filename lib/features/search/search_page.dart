import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'search_provider.dart';
import '../book_detail/book_detail_page.dart';
import '../../core/models/search_book.dart';
import '../../core/models/book_source.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  final BookSource? initialSource;

  const SearchPage({super.key, this.initialQuery, this.initialSource});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null || widget.initialSource != null) {
      _controller.text = widget.initialQuery ?? "";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialSource != null) {
          context.read<SearchProvider>().searchInSource(widget.initialSource!, _controller.text);
        } else {
          context.read<SearchProvider>().search(_controller.text);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    if (value.isNotEmpty) {
      context.read<SearchProvider>().search(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: '搜尋書名或作者',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.white70),
            ),
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.search,
            onSubmitted: _onSearch,
            onChanged: (v) => setState(() {}),
          ),
          actions: [
            Consumer<SearchProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  icon: Icon(provider.isSearching ? Icons.stop_circle_outlined : Icons.search, color: provider.isSearching ? Colors.red : null),
                  onPressed: () {
                    if (provider.isSearching) {
                      provider.stopSearch();
                    } else {
                      _onSearch(_controller.text);
                    }
                  },
                );
              },
            ),
            Consumer<SearchProvider>(
              builder: (context, provider, child) {
                return PopupMenuButton<String>(
                  tooltip: '搜尋範圍',
                  icon: const Icon(Icons.filter_alt),
                  onSelected: provider.setGroup,
                  itemBuilder: (context) {
                    return provider.sourceGroups.map((group) {
                      return CheckedPopupMenuItem<String>(
                        value: group,
                        checked: provider.selectedGroup == group,
                        child: Text(group),
                      );
                    }).toList();
                  },
                );
              },
            ),
          ],
        ),
        body: Consumer<SearchProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                if (provider.isSearching)
                  LinearProgressIndicator(value: provider.progress),
                Expanded(
                  child: provider.results.isEmpty && !provider.isSearching
                      ? _buildHistory(provider)
                      : _buildResults(provider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistory(SearchProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.hotKeywords.isNotEmpty) ...[
          const Text('熱搜詞', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: provider.hotKeywords.map((h) {
              return ActionChip(
                label: Text(h, style: const TextStyle(color: Colors.blue)),
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                onPressed: () {
                  _controller.text = h;
                  _onSearch(h);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (provider.history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('搜尋歷史', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: provider.clearHistory,
                child: const Text('清空'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children:
                provider.history
                    .map(
                      (h) => ActionChip(
                        label: Text(h),
                        onPressed: () {
                          _controller.text = h;
                          _onSearch(h);
                        },
                      ),
                    )
                    .toList(),
          ),
        ],
        if (provider.history.isEmpty && provider.hotKeywords.isEmpty)
          const Center(child: Text('開始搜尋你想看的書吧')),
      ],
    );
  }

  Widget _buildResults(SearchProvider provider) {
    return ListView.builder(
      itemCount: provider.results.length,
      itemBuilder: (context, index) {
        final result = provider.results[index];
        final book = result.book;
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${book.author ?? '未知'} · ${result.sources.length} 個來源'),
              Text(
                result.sources.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailPage(searchBook: result),
              ),
            );
          },
        );
      },
    );
  }
}
