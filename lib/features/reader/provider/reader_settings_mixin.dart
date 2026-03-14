import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';

mixin ReaderSettingsMixin on ChangeNotifier {
  double fontSize = 18.0;
  double lineHeight = 1.5;
  double paragraphSpacing = 1.0;
  double letterSpacing = 0.0;
  double textPadding = 16.0;
  int textIndent = 2;
  double titleTopSpacing = 0.0;
  double titleBottomSpacing = 10.0;
  bool textFullJustify = true;
  int themeIndex = 0;
  double brightness = 1.0;
  int chineseConvert = 0;
  String? fontFamily;
  String backgroundImage = '';
  bool removeSameTitle = false;

  void clearCache();
  void doPaginate();
  Future<void> loadChapter(int index, {bool fromEnd = false});

  Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final fullKey = 'reader_$key';
    if (value is double) { await prefs.setDouble(fullKey, value); }
    else if (value is int) { await prefs.setInt(fullKey, value); }
    else if (value is bool) { await prefs.setBool(fullKey, value); }
    else if (value is String) { await prefs.setString(fullKey, value); }
  }

  void setFontSize(double size) {
    fontSize = size.clamp(12.0, 40.0);
    saveSetting('font_size', fontSize);
    clearCache(); doPaginate();
  }

  void setLineHeight(double height) {
    lineHeight = height.clamp(1.0, 3.0);
    saveSetting('line_height', lineHeight);
    clearCache(); doPaginate();
  }

  void setChineseConvert(int v) {
    if (chineseConvert == v) { return; }
    chineseConvert = v;
    saveSetting('chinese_convert_v2', v);
    clearCache(); loadChapter(0);
  }

  void setTheme(int i) {
    themeIndex = i.clamp(0, AppTheme.readingThemes.length - 1);
    final theme = AppTheme.readingThemes[themeIndex];
    fontSize = theme.textSize; lineHeight = theme.lineSpacing;
    paragraphSpacing = theme.paragraphSpacing; letterSpacing = theme.letterSpacing;
    backgroundImage = theme.backgroundImage ?? "";
    saveSetting('theme_index', themeIndex);
    clearCache(); doPaginate();
  }

  void setBrightness(double v) {
    brightness = v.clamp(0.0, 1.0);
    saveSetting('brightness', v);
    notifyListeners();
  }
}
