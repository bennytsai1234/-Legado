import 'package:flutter/material.dart';
import '../../reader_provider.dart';

class ReaderTopMenu extends StatelessWidget {
  final ReaderProvider provider;
  final VoidCallback onMore;

  const ReaderTopMenu({super.key, required this.provider, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      top: provider.showControls ? 0 : -100,
      left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        color: Colors.black.withValues(alpha: 0.85),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          title: Text(provider.book.name, style: const TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: onMore),
          ],
        ),
      ),
    );
  }
}
