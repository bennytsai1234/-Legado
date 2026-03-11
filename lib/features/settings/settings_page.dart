import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_provider.dart';
import '../replace_rule/replace_rule_page.dart';

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
              _buildSectionTitle('介面外觀'),
              ListTile(
                title: const Text('主題模式'),
                subtitle: Text(_themeModeName(settings.themeMode)),
                leading: const Icon(Icons.brightness_medium_outlined),
                onTap: () => _showThemePicker(context, settings),
              ),
              _buildSectionTitle('閱讀偏好'),
              ListTile(
                title: const Text('翻頁動畫'),
                subtitle: const Text('設定閱讀器翻頁時的視覺效果'),
                leading: const Icon(Icons.animation),
                onTap: () {
                  // 此設定已在 ReaderProvider 中，這裡可連動全域偏好
                },
              ),
              SwitchListTile(
                title: const Text('螢幕常亮'),
                subtitle: const Text('閱讀時防止螢幕自動關閉'),
                secondary: const Icon(Icons.screenshot_outlined),
                value: true, // Placeholder
                onChanged: (v) {},
              ),
              _buildSectionTitle('資料與備份'),
              ListTile(
                title: const Text('WebDAV 備份'),
                subtitle: Text(settings.webdavEnabled ? '已啟用' : '未設定'),
                leading: const Icon(Icons.cloud_upload_outlined),
                onTap: () => _showWebDavConfig(context, settings),
              ),
              ListTile(
                title: const Text('資料庫還原'),
                subtitle: const Text('從備份檔案匯入資料'),
                leading: const Icon(Icons.restore_outlined),
                onTap: () => _restoreDatabase(context, settings),
              ),
              ListTile(
                title: const Text('替換規則'),
                subtitle: const Text('管理正文替換規則'),
                leading: const Icon(Icons.find_replace),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReplaceRulePage(),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('清除快取'),
                subtitle: const Text('刪除所有已快取的章節內容'),
                leading: const Icon(Icons.delete_sweep_outlined),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('確認清除'),
                      content: const Text('這將刪除所有書籍的本地快取內容，確定嗎？'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('清除')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await settings.clearCache();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('快取已清除')));
                    }
                  }
                },
              ),
              _buildSectionTitle('關於'),
              ListTile(
                title: const Text('版本'),
                subtitle: const Text('v0.2.0 (Beta)'),
                leading: const Icon(Icons.info_outline),
              ),
              ListTile(
                title: const Text('開源授權'),
                leading: const Icon(Icons.code),
                onTap: () => _launchUrl('https://github.com/google-gemini/legado-ios'),
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
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟隨系統';
      case ThemeMode.light:
        return '淺色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  void _showThemePicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('選擇主題'),
        children: [
          _themeOption(context, settings, '跟隨系統', ThemeMode.system),
          _themeOption(context, settings, '淺色模式', ThemeMode.light),
          _themeOption(context, settings, '深色模式', ThemeMode.dark),
        ],
      ),
    );
  }

  Widget _themeOption(BuildContext context, SettingsProvider settings, String title, ThemeMode mode) {
    return RadioListTile<ThemeMode>(
      title: Text(title),
      value: mode,
      groupValue: settings.themeMode,
      onChanged: (value) {
        if (value != null) settings.setThemeMode(value);
        Navigator.pop(context);
      },
    );
  }

  void _showWebDavConfig(BuildContext context, SettingsProvider settings) {
    final urlController = TextEditingController(text: settings.webdavUrl);
    final userController = TextEditingController(text: settings.webdavUser);
    final passController = TextEditingController(text: settings.webdavPassword);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WebDAV 設定'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: urlController, decoration: const InputDecoration(labelText: '伺服器位址')),
              TextField(controller: userController, decoration: const InputDecoration(labelText: '帳號')),
              TextField(controller: passController, decoration: const InputDecoration(labelText: '密碼'), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              await settings.updateWebDav(
                url: urlController.text,
                user: userController.text,
                password: passController.text,
              );
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('儲存'),
          ),
        ],
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
