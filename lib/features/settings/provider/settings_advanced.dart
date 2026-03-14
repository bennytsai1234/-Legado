import 'settings_base.dart';

/// SettingsProvider 的進階配置擴展
extension SettingsAdvanced on SettingsProviderBase {
  Future<void> setCoverSearchPriority(int val) async { (this as dynamic).coverSearchPriority = val; await save('cover_search_priority', val); notifyListeners(); }
  Future<void> setCoverTimeout(int val) async { (this as dynamic).coverTimeout = val; await save('cover_timeout', val); notifyListeners(); }
  Future<void> setGlobalCoverRule(String val) async { (this as dynamic).globalCoverRule = val; await save('global_cover_rule', val); notifyListeners(); }

  Future<void> setPrivacyAgreed(bool value) async { (this as dynamic).privacyAgreed = value; await save('privacy_agreed', value); notifyListeners(); }
  Future<void> setRecordLog(bool v) async { (this as dynamic).recordLog = v; await save('record_log', v); notifyListeners(); }
}
