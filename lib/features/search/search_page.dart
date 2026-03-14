import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'search_provider.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'widgets/search_app_bar.dart';
import 'widgets/search_history_view.dart';
import 'widgets/search_result_item.dart';

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
    return Consumer<SearchProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: SearchAppBar(controller: _controller, provider: provider, onSearch: _onSearch),
          body: Column(
            children: [
              if (provider.isSearching) ...[
                LinearProgressIndicator(value: provider.progress, backgroundColor: Colors.transparent, valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue)),
                _buildCurrentSourcePanel(provider),
              ],
              if (provider.selectedGroup != '全部') _buildFilterStatusPanel(provider),
              Expanded(
                child: provider.results.isEmpty && !provider.isSearching
                    ? SearchHistoryView(provider: provider, controller: _controller, onSearch: _onSearch)
                    : _buildResults(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentSourcePanel(SearchProvider p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        width: double.infinity,
        color: Colors.blue.withValues(alpha: 0.05),
        child: Text('正在搜尋: ${p.currentSource}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
      );

  Widget _buildFilterStatusPanel(SearchProvider p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: Colors.blue.withValues(alpha: 0.1),
        child: Row(children: [
          const Icon(Icons.filter_list, size: 14, color: Colors.blue),
          const SizedBox(width: 8),
          Text('正在過濾分組: ${p.selectedGroup}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
          const Spacer(),
          GestureDetector(onTap: () => p.setGroup('全部'), child: const Text('重設', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold))),
        ]),
      );

  Widget _buildResults(SearchProvider p) => ListView.separated(
        itemCount: p.results.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1),
        itemBuilder: (ctx, i) => SearchResultItem(result: p.results[i]),
      );
}
