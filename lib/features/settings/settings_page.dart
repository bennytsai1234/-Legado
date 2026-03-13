import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'backup_settings_page.dart';
import 'reading_settings_page.dart';
import 'theme_settings_page.dart';
import 'welcome_settings_page.dart';
import 'icon_settings_page.dart';
import 'font_manager_page.dart';
import '../dict/dict_rule_page.dart';
import 'other_settings_page.dart';
import 'aloud_settings_page.dart';
import '../cache_manager/download_manager_page.dart';
import '../about/about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildListTile(
                context,
                icon: Icons.palette_outlined,
                title: '主題設定',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ThemeSettingsPage()),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.style_outlined,
                title: '歡迎界面設定',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeSettingsPage()),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.grid_view_outlined,
                title: '更換圖標',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const IconSettingsPage()),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.menu_book_outlined,
                title: '閱讀設定',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReadingSettingsPage()),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.record_voice_over_outlined,
                title: '朗讀設定',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AloudSettingsPage()),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.font_download_outlined,
                title: '字體管理',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FontManagerPage()),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.translate_outlined,
                title: '字典管理',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DictRulePage()),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.backup_outlined,
                title: '備份與還原',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BackupSettingsPage()),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.download_for_offline_outlined,
                title: '下載管理',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DownloadManagerPage()),
                  );
                },
              ),
              _buildListTile(
                context,
                icon: Icons.more_horiz_outlined,
                title: '其他設定',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OtherSettingsPage()),
                  );
                },
              ),
              const Divider(),
              _buildListTile(
                context,
                icon: Icons.info_outline,
                title: '關於',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
