import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildSectionTitle('外觀設定'),
              ListTile(
                title: const Text('深色模式'),
                subtitle: Text(_getThemeModeName(settings.themeMode)),
                leading: const Icon(Icons.palette_outlined),
                onTap: () => _showThemeDialog(context, settings),
              ),
              
              _buildSectionTitle('資料維護'),
              ListTile(
                title: const Text('資料庫備份'),
                subtitle: const Text('匯出當前資料庫檔案'),
                leading: const Icon(Icons.backup_outlined),
                onTap: () async {
                  final path = await settings.backupDatabase();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(path != null ? '備份成功: $path' : '備份失敗')),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('資料庫還原'),
                subtitle: const Text('從備份檔案匯入資料'),
                leading: const Icon(Icons.restore_outlined),
                onTap: () => _restoreDatabase(context, settings),
              ),
              ListTile(
                title: const Text('清除快取'),
                subtitle: const Text('刪除所有已快取的章節內容'),
                leading: const Icon(Icons.delete_sweep_outlined),
                onTap: () async {
                  await settings.clearCache();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('快取已清除')),
                    );
                  }
                },
              ),

              _buildSectionTitle('關於'),
              const ListTile(
                title: Text('版本'),
                subtitle: Text('1.0.0 (Beta)'),
                leading: Icon(Icons.info_outline),
              ),
              ListTile(
                title: const Text('GitHub 原始碼'),
                subtitle: const Text('https://github.com/legado/legado-ios'),
                leading: const Icon(Icons.code),
                onTap: () => _launchUrl('https://github.com/legado/legado-ios'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return '開啟';
      case ThemeMode.dark: return '關閉';
      case ThemeMode.system: return '跟隨系統';
    }
  }

  void _showThemeDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('深色模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('跟隨系統'),
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged: (v) { settings.setThemeMode(v!); Navigator.pop(context); },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('開啟'),
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (v) { settings.setThemeMode(v!); Navigator.pop(context); },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('關閉'),
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (v) { settings.setThemeMode(v!); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreDatabase(BuildContext context, SettingsProvider settings) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final success = await settings.restoreDatabase(result.files.single.path!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? '還原成功，請重啟 App' : '還原失敗')),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
