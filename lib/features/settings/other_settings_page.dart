import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

class OtherSettingsPage extends StatelessWidget {
  const OtherSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('其他設定')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              ListTile(
                title: const Text('語言 (Language)'),
                subtitle: const Text('跟隨系統 / 繁體中文 / 简体中文 / English'),
                leading: const Icon(Icons.language),
                onTap: () => _showComingSoon(context),
              ),
              const Divider(),
              _buildSectionTitle('主介面'),
              SwitchListTile(
                title: const Text('下拉自動更新'),
                subtitle: const Text('開啟後進入書架自動重新整理'),
                value: settings.autoRefresh,
                onChanged: (v) => settings.setAutoRefresh(v),
              ),
              SwitchListTile(
                title: const Text('預設展開書籍'),
                value: settings.defaultToRead,
                onChanged: (v) => settings.setDefaultToRead(v),
              ),
              SwitchListTile(
                title: const Text('顯示發現'),
                value: settings.showDiscovery,
                onChanged: (v) => settings.setShowDiscovery(v),
              ),
              SwitchListTile(
                title: const Text('顯示 RSS'),
                value: settings.showRss,
                onChanged: (v) => settings.setShowRss(v),
              ),
              ListTile(
                title: const Text('預設首頁'),
                subtitle: const Text('啟動 App 時預設顯示的頁面'),
                onTap: () => _showComingSoon(context),
              ),
              const Divider(),
              _buildSectionTitle('其他設定'),
              ListTile(
                title: const Text('設置密碼'),
                subtitle: const Text('開啟 App 時需輸入密碼解鎖'),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('User Agent'),
                subtitle: const Text('變更網路請求的預設 User-Agent'),
                onTap: () => _showComingSoon(context),
              ),
              SwitchListTile(
                title: const Text('Web 服務保留喚醒鎖'),
                value: settings.webServiceWakeLock,
                onChanged: (v) => settings.setWebServiceWakeLock(v),
              ),
              ListTile(
                title: const Text('書籍存放目錄'),
                subtitle: const Text('設定本地匯出或下載書籍的預設目錄'),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('編輯書源最大行數'),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('校驗書源'),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('全域封面規則'),
                subtitle: Text(settings.globalCoverRule.isEmpty ? '未設定' : '已設定 (點擊編輯)'),
                onTap: () => _showAdvancedCoverConfig(context, settings),
              ),
              ListTile(
                title: const Text('直鏈上傳規則'),
                onTap: () => _showComingSoon(context),
              ),
              SwitchListTile(
                title: const Text('啟用 Cronet'),
                subtitle: const Text('使用 Chromium 網路堆疊 (實驗性)'),
                value: settings.enableCronet,
                onChanged: (v) => settings.setEnableCronet(v),
              ),
              SwitchListTile(
                title: const Text('圖片抗鋸齒'),
                value: settings.antiAlias,
                onChanged: (v) => settings.setAntiAlias(v),
              ),
              ListTile(
                title: const Text('圖片快取大小'),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('預先下載章節數'),
                onTap: () => _showComingSoon(context),
              ),
              SwitchListTile(
                title: const Text('預設啟用替換規則'),
                value: settings.replaceEnableDefault,
                onChanged: (v) => settings.setReplaceEnableDefault(v),
              ),
              SwitchListTile(
                title: const Text('退出時暫停媒體按鍵'),
                value: settings.mediaButtonOnExit,
                onChanged: (v) => settings.setMediaButtonOnExit(v),
              ),
              SwitchListTile(
                title: const Text('媒體鍵朗讀'),
                value: settings.readAloudByMediaButton,
                onChanged: (v) => settings.setReadAloudByMediaButton(v),
              ),
              SwitchListTile(
                title: const Text('忽略音訊焦點'),
                value: settings.ignoreAudioFocus,
                onChanged: (v) => settings.setIgnoreAudioFocus(v),
              ),
              SwitchListTile(
                title: const Text('自動清理過期數據'),
                value: settings.autoClearExpired,
                onChanged: (v) => setSettingsProvider(context, (s) => s.setAutoClearExpired(v)),
              ),
              SwitchListTile(
                title: const Text('顯示加入書架提示'),
                value: settings.showAddToShelfAlert,
                onChanged: (v) => setSettingsProvider(context, (s) => s.setShowAddToShelfAlert(v)),
              ),
              SwitchListTile(
                title: const Text('顯示漫畫 UI'),
                value: settings.showMangaUi,
                onChanged: (v) => setSettingsProvider(context, (s) => s.setShowMangaUi(v)),
              ),
              ListTile(
                title: const Text('Web 服務連接埠 (Port)'),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('清除快取'),
                subtitle: const Text('清理圖片、書籍快取等資料'),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('清除 Webview 資料'),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('壓縮資料庫 (Shrink)'),
                subtitle: const Text('優化並壓縮 Sqlite 資料庫尺寸'),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('執行緒數量'),
                subtitle: Text('${settings.threadCount} (併發請求數量)'),
                onTap: () => _showThreadCountDialog(context, settings),
              ),
              SwitchListTile(
                title: const Text('加入系統文字選擇選單'),
                value: settings.processText,
                onChanged: (v) => setSettingsProvider(context, (s) => s.setProcessText(v)),
              ),
              SwitchListTile(
                title: const Text('記錄除錯日誌 (Log)'),
                value: settings.recordLog,
                onChanged: (v) => setSettingsProvider(context, (s) => s.setRecordLog(v)),
              ),
              SwitchListTile(
                title: const Text('記錄 Heap Dump'),
                value: settings.recordHeapDump,
                onChanged: (v) => setSettingsProvider(context, (s) => s.setRecordHeapDump(v)),
              ),
            ],
          );
        },
      ),
    );
  }

  void setSettingsProvider(BuildContext context, Function(SettingsProvider) callback) {
    callback(context.read<SettingsProvider>());
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('功能開發中 (Work in Progress)')),
    );
  }

  void _showThreadCountDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) {
        double currentVal = settings.threadCount.toDouble();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('設定執行緒數量: ${currentVal.toInt()}'),
              content: Slider(
                value: currentVal,
                min: 1,
                max: 32,
                divisions: 31,
                onChanged: (val) {
                  setState(() {
                    currentVal = val;
                  });
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                TextButton(
                  onPressed: () {
                    settings.setThreadCount(currentVal.toInt());
                    Navigator.pop(context);
                  },
                  child: const Text('確定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAdvancedCoverConfig(BuildContext context, SettingsProvider settings) {
    final ruleController = TextEditingController(text: settings.globalCoverRule);
    showDialog(
      context: context,
      builder: (context) {
        int priority = settings.coverSearchPriority;
        double timeout = settings.coverTimeout.toDouble();
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('進階封面設定'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: priority,
                      decoration: const InputDecoration(labelText: '搜尋優先級'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('書源優先')),
                        DropdownMenuItem(value: 1, child: Text('全域規則優先')),
                      ],
                      onChanged: (val) => setState(() => priority = val!),
                    ),
                    const SizedBox(height: 16),
                    Text('超時時間: ${(timeout / 1000).toStringAsFixed(1)} 秒'),
                    Slider(
                      value: timeout,
                      min: 1000,
                      max: 30000,
                      divisions: 29,
                      onChanged: (val) => setState(() => timeout = val),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ruleController,
                      decoration: const InputDecoration(
                        labelText: '全域規則 (每行一個 URL)',
                        hintText: '例: https://example.com/cover/{{key}}.jpg',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                TextButton(
                  onPressed: () {
                    settings.setCoverSearchPriority(priority);
                    settings.setCoverTimeout(timeout.toInt());
                    settings.setGlobalCoverRule(ruleController.text);
                    Navigator.pop(context);
                  },
                  child: const Text('儲存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGlobalCoverRuleDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.globalCoverRule);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('全域封面規則'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '輸入 JSON 格式的封面覆蓋規則'),
            maxLines: 5,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(
              onPressed: () {
                settings.setGlobalCoverRule(controller.text);
                Navigator.pop(context);
              },
              child: const Text('儲存'),
            ),
          ],
        );
      },
    );
  }
}
