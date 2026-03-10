/// Settings Page - 設定頁面
/// 對應 Android: ui/config/*
library;

import 'package:flutter/material.dart';

// TODO: 實作
// - [ ] 主題設定 (亮/暗/跟隨系統)
// - [ ] 閱讀設定
// - [ ] WebDAV 備份
// - [ ] 資料庫備份/還原
// - [ ] 清除快取
// - [ ] 關於

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主題設定'),
            onTap: () {
              // TODO
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('閱讀設定'),
            onTap: () {
              // TODO
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('WebDAV 備份'),
            onTap: () {
              // TODO
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('資料庫備份/還原'),
            onTap: () {
              // TODO
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('清除快取'),
            onTap: () {
              // TODO
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('關於'),
            subtitle: const Text('Legado Reader v0.1.0'),
            onTap: () {
              // TODO
            },
          ),
        ],
      ),
    );
  }
}
