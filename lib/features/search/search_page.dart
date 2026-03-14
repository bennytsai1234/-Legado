import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'search_provider.dart';
import '../book_detail/book_detail_page.dart';
import '../../core/models/book_source.dart';
import '../../core/widgets/book_cover_widget.dart';

class SearchPage extends StatelessWidget {
  final String? initialQuery;
  final BookSource? initialSource;

  const SearchPage({super.key, this.initialQuery, this.initialSource});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(),
      child: _SearchPageContent(initialQuery: initialQuery, initialSource: initialSource),
    );
  }
}

class _SearchPageContent extends StatefulWidget {
  final String? initialQuery;
  final BookSource? initialSource;

  const _SearchPageContent({this.initialQuery, this.initialSource});

  @override
  State<_SearchPageContent> createState() => _SearchPageContentState();
}

class _SearchPageContentState extends State<_SearchPageContent> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null || widget.initialSource != null) {
      _controller.text = widget.initialQuery ?? "";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<SearchProvider>();
        if (widget.initialSource != null) {
          provider.searchInSource(widget.initialSource!, _controller.text);
        } else {
          provider.search(_controller.text);
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
    return Scaffold(
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
                tooltip: '搜尋分組',
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
              if (provider.isSearching) ...[
                LinearProgressIndicator(value: provider.progress, backgroundColor: Colors.transparent, valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  width: double.infinity,
                  color: Colors.blue.withValues(alpha: 0.05),
                  child: Text(
                    '正在搜尋: ${provider.currentSource}',
                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (provider.selectedGroup != '全部')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: Colors.blue.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 14, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('正在過濾分組: ${provider.selectedGroup}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => provider.setGroup('全部'),
                        child: const Text('重設', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: provider.results.isEmpty && !provider.isSearching
                    ? _buildHistory(provider)
                    : _buildResults(provider),
              ),
            ],
          );
        },
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
          leading: BookCoverWidget(
            coverUrl: book.coverUrl,
            bookName: book.name,
            author: book.author,
            width: 45,
            height: 60,
            borderRadius: BorderRadius.circular(4),
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
