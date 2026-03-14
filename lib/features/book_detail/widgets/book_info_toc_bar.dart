import 'package:flutter/material.dart';
import '../book_detail_provider.dart';

class BookInfoTocBar extends StatelessWidget {
  final BookDetailProvider provider;
  final VoidCallback onSearch;

  const BookInfoTocBar({super.key, required this.provider, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('目錄 (${provider.filteredChapters.length} 章)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.search), onPressed: onSearch),
                IconButton(icon: Icon(provider.isReversed ? Icons.vertical_align_top : Icons.vertical_align_bottom), onPressed: provider.toggleSort),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
