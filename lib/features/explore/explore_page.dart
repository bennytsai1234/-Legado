/// Explore Page - 發現/探索頁面
/// 對應 Android: ui/main/explore/*
library;

import 'package:flutter/material.dart';

// TODO: 實作
// - [ ] 書源分組顯示
// - [ ] 分頁流式載入
// - [ ] 篩選條件
// - [ ] 點擊進入書籍詳情

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('發現'),
      ),
      body: const Center(
        child: Text('發現 - 待實作', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
