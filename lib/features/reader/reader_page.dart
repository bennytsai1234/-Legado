/// Reader Page - 閱讀器頁面
/// 對應 Android: ui/book/read/*
library;

import 'package:flutter/material.dart';

// TODO: 實作
// - [ ] 翻頁動畫 (水平/仿真/覆蓋/滑動)
// - [ ] 文字排版引擎 (段落分頁)
// - [ ] 閱讀進度條
// - [ ] 閱讀設定面板 (字體、字號、行距、背景)
// - [ ] 書籤系統
// - [ ] TTS 朗讀
// - [ ] 長按選字
// - [ ] 自動翻頁
// - [ ] 繁簡轉換
// - [ ] 內文搜尋

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('閱讀器 - 待實作', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
