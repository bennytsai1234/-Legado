import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

class AloudSettingsPage extends StatelessWidget {
  const AloudSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('朗讀設定')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('忽略音訊焦點'),
                subtitle: const Text('被其他應用程式搶佔音訊時不暫停朗讀'),
                value: settings.ignoreAudioFocusAloud,
                onChanged: (v) => settings.setIgnoreAudioFocusAloud(v),
              ),
              SwitchListTile(
                title: const Text('通話時暫停朗讀'),
                subtitle: const Text('來電或通話時自動暫停 TTS'),
                value: settings.pauseReadAloudWhilePhoneCalls,
                onChanged: (v) => settings.setPauseReadAloudWhilePhoneCalls(v),
              ),
              SwitchListTile(
                title: const Text('朗讀時保持喚醒'),
                subtitle: const Text('朗讀期間防止系統休眠降低耗電，但可能失效'),
                value: settings.readAloudWakeLock,
                onChanged: (v) => settings.setReadAloudWakeLock(v),
              ),
              SwitchListTile(
                title: const Text('相容系統媒體控制'),
                subtitle: const Text('部分耳機線控無效時嘗試開啟此項'),
                value: settings.systemMediaControlCompatibilityChange,
                onChanged: (v) => settings.setSystemMediaControlCompatibilityChange(v),
              ),
              SwitchListTile(
                title: const Text('線控上一首/下一首翻頁'),
                subtitle: const Text('將耳機線控上一首/下一首對應為朗讀上一頁/下一頁'),
                value: settings.mediaButtonPerNext,
                onChanged: (v) => settings.setMediaButtonPerNext(v),
              ),
              SwitchListTile(
                title: const Text('按頁朗讀'),
                subtitle: const Text('每讀完一頁才載入下一頁，預設為按段落朗讀'),
                value: settings.readAloudByPage,
                onChanged: (v) => settings.setReadAloudByPage(v),
              ),
              SwitchListTile(
                title: const Text('使用音訊流朗讀'),
                subtitle: const Text('部分引擎合成語音可能較慢，可切換此項測試'),
                value: settings.streamReadAloudAudio,
                onChanged: (v) => settings.setStreamReadAloudAudio(v),
              ),
              ListTile(
                title: const Text('發音引擎'),
                subtitle: const Text('TTS'),
                leading: const Icon(Icons.record_voice_over),
                onTap: () => _showComingSoon(context),
              ),
              ListTile(
                title: const Text('系統 TTS 設定'),
                subtitle: const Text('前往系統內建的文字轉語音設定頁面'),
                leading: const Icon(Icons.settings_voice),
                onTap: () => _showComingSoon(context),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('功能開發中 (Work in Progress)')),
    );
  }
}
