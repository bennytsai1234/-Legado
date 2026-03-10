import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'search_provider.dart';
import '../book_detail/book_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    if (value.trim().isEmpty) return;
    _focusNode.unfocus();
    context.read<SearchProvider>().search(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '搜尋書名、作者...',
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                  },
                )
              : null,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _onSearch,
          onChanged: (v) => setState(() {}),
        ),
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
    );
  }

  Widget _buildHistory(SearchProvider provider) {
    if (provider.history.isEmpty) {
      return const Center(child: Text('開始搜尋你想看的書吧'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: resolve(MainAxisAlignment.spaceBetween),
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
          children: provider.history.map((h) => ActionChip(
            label: Text(h),
            onPressed: () {
              _controller.text = h;
              _onSearch(h);
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildResults(SearchProvider provider) {
    return ListView.separated(
      itemCount: provider.results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final aggregated = provider.results[index];
        final book = aggregated.book;
        return ListTile(
          leading: SizedBox(
            width: 50,
            height: 70,
            child: book.coverUrl != null && book.coverUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: book.coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.book),
                )
              : Container(color: Colors.grey[200], child: const Icon(Icons.book)),
          ),
          title: Text(book.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${book.author ?? '未知'} · ${aggregated.sources.length}個來源'),
              if (book.latestChapterTitle != null)
                Text(
                  '最新: ${book.latestChapterTitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
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
    );
  }

  MainAxisAlignment resolve(MainAxisAlignment val) => val; // Helper for alignment
}
