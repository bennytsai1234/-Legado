import 'package:flutter/material.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';

class ReaderMenuTop extends StatelessWidget {
  final ReaderProvider provider;
  final VoidCallback onMoreMenu;

  const ReaderMenuTop({
    super.key,
    required this.provider,
    required this.onMoreMenu,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: provider.showControls ? 0 : -100,
      left: 0,
      right: 0,
      child: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          provider.book.name,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () => provider.toggleBookmark(),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: onMoreMenu,
          ),
        ],
      ),
    );
  }
}
