/// Source Manager Page - 書源管理頁面
/// 對應 Android: ui/book/source/*
library;

import 'package:flutter/material.dart';

// TODO: 實作
// - [ ] 書源列表 (啟用/禁用)
// - [ ] 書源匯入 (URL / 剪貼簿 / 掃碼)
// - [ ] 書源編輯器
// - [ ] 書源分組管理
// - [ ] 書源排序
// - [ ] 書源批量校驗
// - [ ] 書源匯出/分享
// - [ ] 書源登入

class SourceManagerPage extends StatefulWidget {
  const SourceManagerPage({super.key});

  @override
  State<SourceManagerPage> createState() => _SourceManagerPageState();
}

class _SourceManagerPageState extends State<SourceManagerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('書源管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Import book source
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('書源管理 - 待實作', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
