/// Search Page - 搜尋頁面
/// 對應 Android: ui/book/search/*
library;

import 'package:flutter/material.dart';

// TODO: 實作
// - [ ] 多源並行搜尋
// - [ ] 搜尋結果聚合去重
// - [ ] 搜尋歷史
// - [ ] 搜尋範圍限制
// - [ ] 併發控制

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜尋書名或作者',
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            // TODO: Trigger search
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Trigger search
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('輸入關鍵字開始搜尋', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
