import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'settings_provider.dart';
import '../replace_rule/replace_rule_page.dart';
import '../source_manager/source_manager_page.dart';
import 'theme_settings_page.dart';
import 'other_settings_page.dart';
import 'aloud_settings_page.dart';

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
              // 1. 書源管理
              ListTile(
                title: const Text('書源管理'),
                subtitle: const Text('管理各大小說網站書源'),
                leading: const Icon(Icons.source_outlined),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SourceManagerPage()),
                  );
                },
              ),
              // 2. 文字目錄規則 (暫未完整實作，用佔位符)
              ListTile(
                title: const Text('文字目錄規則'),
                subtitle: const Text('設定本地 TXT 書籍的目錄解析規則'),
                leading: const Icon(Icons.rule_folder_outlined),
                onTap: () => _showComingSoon(context),
              ),
              // 3. 替換淨化
              ListTile(
                title: const Text('替換淨化'),
                subtitle: const Text('管理正文替換規則，過濾廣告與錯字'),
                leading: const Icon(Icons.find_replace),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReplaceRulePage()),
                  );
                },
              ),
              // 4. 字典規則 (暫未完整實作)
              ListTile(
                title: const Text('字典規則'),
                subtitle: const Text('設定閱讀器長按查詞規則'),
                leading: const Icon(Icons.translate),
                onTap: () => _showComingSoon(context),
              ),
              // 5. 主題模式
              ListTile(
                title: const Text('主題模式'),
                subtitle: Text(_themeModeName(settings.themeMode)),
                leading: const Icon(Icons.brightness_medium_outlined),
                onTap: () => _showThemePicker(context, settings),
              ),
              // 6. Web 服務
              SwitchListTile(
                title: const Text('Web 服務'),
                subtitle: const Text('開啟後可透過瀏覽器遠端傳書/管理介面'),
                secondary: const Icon(Icons.wifi_tethering),
                value: false, // Placeholder
                onChanged: (v) => _showComingSoon(context),
              ),

              _buildSectionTitle('設定'),
              // 7. 備份與恢復 (WebDAV)
              ListTile(
                title: const Text('備份與恢復'),
                subtitle: const Text('WebDAV 同步及本地資料庫還原'),
                leading: const Icon(Icons.backup_outlined),
                onTap: () => _showWebDavConfig(context, settings),
              ),
              // 8. 主題設定
              ListTile(
                title: const Text('主題設定'),
                subtitle: const Text('自訂背景顏色、文字顏色與 UI 風格'),
                leading: const Icon(Icons.color_lens_outlined),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ThemeSettingsPage()),
                  );
                },
              ),
              // 9. 其他設定
              ListTile(
                title: const Text('其他設定'),
                subtitle: const Text('快取、網路逾時、預設字體與進階選項'),
                leading: const Icon(Icons.settings_suggest_outlined),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OtherSettingsPage()),
                  );
                },
              ),
              // 9-1. 朗讀設定
              ListTile(
                title: const Text('朗讀設定'),
                subtitle: const Text('發音引擎、媒體按鍵控制、語調配置'),
                leading: const Icon(Icons.record_voice_over_outlined),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AloudSettingsPage()),
                  );
                },
              ),

              _buildSectionTitle('其他'),
              // 10. 所有書籤
              ListTile(
                title: const Text('所有書籤'),
                subtitle: const Text('瀏覽所有書籤紀錄'),
                leading: const Icon(Icons.bookmark_border),
                onTap: () => _showComingSoon(context),
              ),
              // 11. 閱讀紀錄
              ListTile(
                title: const Text('閱讀紀錄'),
                subtitle: const Text('檢視最近閱讀與歷史紀錄'),
                leading: const Icon(Icons.history),
                onTap: () => _showComingSoon(context),
              ),
              // 12. 檔案管理
              ListTile(
                title: const Text('檔案管理'),
                subtitle: const Text('匯出或管理本地的快取與書籍檔案'),
                leading: const Icon(Icons.folder_open),
                onTap: () => _showComingSoon(context),
              ),
              // 13. 關於
              ListTile(
                title: const Text('關於'),
                leading: const Icon(Icons.info_outline),
                onTap: () => _showAboutDialog(context),
              ),
              // 14. 退出
              ListTile(
                title: const Text('退出'),
                leading: const Icon(Icons.exit_to_app),
                onTap: () => SystemNavigator.pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在建置中，敬請期待 (Work in progress)')),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
        title: const Text('備份與恢復 (WebDAV)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: urlController, decoration: const InputDecoration(labelText: '伺服器位址')),
              TextField(controller: userController, decoration: const InputDecoration(labelText: '帳號')),
              TextField(controller: passController, decoration: const InputDecoration(labelText: '密碼'), obscureText: true),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _restoreDatabase(context, settings),
                child: const Text('從本地資料庫檔還原'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  final dbPath = await settings.backupDatabase();
                  if (!context.mounted) return;
                  if (dbPath != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('備份成功: \$dbPath')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('備份失敗')));
                  }
                },
                child: const Text('導出本地資料庫備份'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
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
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('快取已清除')));
                  }
                },
                child: const Text('手動清除閱讀快取'),
              )
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
            child: const Text('儲存 WebDAV'),
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('關於 Legado iOS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('v0.2.0 (Beta Flutter Port)\n'),
            const Text('基於 Android 開源項目 Legado 打造的全功能閱讀器。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl('https://github.com/google-gemini/legado-ios');
            },
            child: const Text('前往原始碼'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉')),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
