/// Bookshelf Page - 書架頁面 (主頁)
/// 對應 Android: ui/main/bookshelf/*
library;

import 'package:flutter/material.dart';

// TODO: 實作
// - [ ] 網格/列表模式切換
// - [ ] 書架分組
// - [ ] 下拉更新 (檢查新章節)
// - [ ] 長按拖拉排序
// - [ ] 新章節紅點提示
// - [ ] 快取下載進度

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('書架'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to search
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('書架 - 待實作', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
