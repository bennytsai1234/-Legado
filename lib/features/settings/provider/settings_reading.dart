import 'settings_base.dart';
import 'package:legado_reader/core/constant/prefer_key.dart';

/// SettingsProvider 的閱讀配置擴展
extension SettingsReading on SettingsProviderBase {
  Future<void> setHideStatusBar(bool v) async { (this as dynamic).hideStatusBar = v; await save('hide_status_bar', v); notifyListeners(); }
  Future<void> setHideNavigationBar(bool v) async { (this as dynamic).hideNavigationBar = v; await save('hide_navigation_bar', v); notifyListeners(); }
  Future<void> setVolumeKeyPage(bool v) async { (this as dynamic).volumeKeyPage = v; await save('volume_key_page', v); notifyListeners(); }
  Future<void> setAutoChangeSource(bool v) async { (this as dynamic).autoChangeSource = v; await save('auto_change_source', v); notifyListeners(); }
  Future<void> setOptimizeRender(bool v) async { (this as dynamic).optimizeRender = v; await save('optimize_render', v); notifyListeners(); }

  // 朗讀設定
  Future<void> setSpeechRate(double v) async { (this as dynamic).speechRate = v; await save(PreferKey.ttsSpeechRate, v); notifyListeners(); }
  Future<void> setSpeechPitch(double v) async { (this as dynamic).speechPitch = v; await save('speech_pitch', v); notifyListeners(); }
  Future<void> setSpeechVolume(double v) async { (this as dynamic).speechVolume = v; await save('speech_volume', v); notifyListeners(); }
}
