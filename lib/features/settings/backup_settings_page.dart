import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'settings_provider.dart';

class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  final TextEditingController _webdavUrlController = TextEditingController();
  final TextEditingController _webdavUserController = TextEditingController();
  final TextEditingController _webdavPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _webdavUrlController.text = settings.webdavUrl;
    _webdavUserController.text = settings.webdavUser;
    _webdavPasswordController.text = settings.webdavPassword;
  }

  @override
  void dispose() {
    _webdavUrlController.dispose();
    _webdavUserController.dispose();
    _webdavPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('備份與還原')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              _buildSectionTitle('WebDAV 設定'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _webdavUrlController,
                      decoration: const InputDecoration(
                        labelText: 'WebDAV 伺服器網址',
                        hintText: '例如: https://dav.jianguoyun.com/dav/',
                      ),
                      onChanged: (v) => _saveWebdavAccount(settings),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _webdavUserController,
                      decoration: const InputDecoration(labelText: 'WebDAV 帳號'),
                      onChanged: (v) => _saveWebdavAccount(settings),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _webdavPasswordController,
                      decoration: const InputDecoration(labelText: 'WebDAV 密碼/授權碼'),
                      obscureText: true,
                      onChanged: (v) => _saveWebdavAccount(settings),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('子目錄 (Sub Directory)'),
                subtitle: const Text('留空為根目錄'),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('裝置名稱 (Device Name)'),
                subtitle: const Text('用於區分不同裝置的備份'),
                onTap: () => _showComingSoon(context),
              ),
              SwitchListTile(
                title: const Text('同步書籍進度'),
                subtitle: const Text('開啟後會自動將閱讀進度同步到 WebDAV'),
                value: settings.syncBookProgress,
                onChanged: (v) => settings.setSyncBookProgress(v),
              ),
              SwitchListTile(
                title: const Text('增加同步範圍'),
                subtitle: const Text('同時同步書籤、書源、字體等進階資料'),
                value: settings.syncBookProgressPlus,
                onChanged: settings.syncBookProgress ? (v) => settings.setSyncBookProgressPlus(v) : null,
              ),

              const Divider(),
              _buildSectionTitle('本地備份與還原'),
              ListTile(
                title: const Text('選擇本地備份目錄'),
                subtitle: const Text('設定或變更本地配置備份的資料夾'),
                leading: const Icon(Icons.folder_open),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('手動備份 (WebDAV / Local)'),
                subtitle: const Text('將目前所有書架與配置進行備份'),
                leading: const Icon(Icons.backup_outlined),
                onTap: () async {
                  final path = await settings.backupDatabase();
                  if (context.mounted && path != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('備份成功: $path')));
                  }
                },
              ),
              ListTile(
                title: const Text('手動還原 (WebDAV / Local)'),
                subtitle: const Text('從備份檔恢復書架與配置 (會覆蓋現有資料)'),
                leading: const Icon(Icons.restore),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null && result.files.single.path != null) {
                    final success = await settings.restoreDatabase(result.files.single.path!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? '還原成功，請重啟 APP' : '還原取消或失敗')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                title: const Text('還原忽略項目'),
                subtitle: const Text('設定還原時保留現有的哪些設定檔'),
                leading: const Icon(Icons.rule),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('匯入舊版資料'),
                leading: const Icon(Icons.import_export),
                onTap: () => _showComingSoon(context),
              ),
              SwitchListTile(
                title: const Text('僅保留最新備份'),
                subtitle: const Text('自動刪除舊有的備份檔案以節省空間'),
                value: settings.onlyLatestBackup,
                onChanged: (v) => settings.setOnlyLatestBackup(v),
              ),
              SwitchListTile(
                title: const Text('自動檢查新備份'),
                subtitle: const Text('開啟 APP 時自動檢查 WebDAV 是否有較新進度'),
                value: settings.autoCheckNewBackup,
                onChanged: (v) => settings.setAutoCheckNewBackup(v),
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

  void _saveWebdavAccount(SettingsProvider settings) {
    settings.updateWebDav(
      url: _webdavUrlController.text,
      user: _webdavUserController.text,
      password: _webdavPasswordController.text,
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('功能開發中 (Work in Progress)')),
    );
  }
}
