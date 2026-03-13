import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// App Theme - 主題配置
/// 對應 Android: help/config/ReadBookConfig.kt 與 ThemeConfig.kt
class AppTheme {
  // ... (保留原有的色彩與主題定義)
  static const Color primaryColor = Color(0xFF5B7FFF);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color darkBackgroundColor = Color(0xFF0F172A);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: primaryColor,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: primaryColor,
  );

  /// 閱讀排版配置清單 (對標 Android configList)
  static List<ReadingTheme> readingThemes = [];

  /// 初始化排版配置 (對標 initConfigs)
  static Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final configFile = File('${directory.path}/readConfig.json');

    if (await configFile.exists()) {
      try {
        final jsonStr = await configFile.readAsString();
        final List<dynamic> list = jsonDecode(jsonStr);
        readingThemes = list.map((e) => ReadingTheme.fromJson(e)).toList();
      } catch (e) {
        debugPrint("Error loading reading configs from file: $e");
      }
    }

    if (readingThemes.isEmpty) {
      await _loadDefaultConfigs();
    }
  }

  static Future<void> _loadDefaultConfigs() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/default_sources/readConfig.json');
      final List<dynamic> list = jsonDecode(jsonStr);
      readingThemes = list.map((e) => ReadingTheme.fromJson(e)).toList();
    } catch (e) {
      // 最終回退硬編碼配置
      readingThemes = _fallbackThemes;
    }
  }

  static const List<ReadingTheme> _fallbackThemes = [
    ReadingTheme(name: '預設', backgroundColor: Color(0xFFFFFFFF), textColor: Color(0xFF1A1A1A)),
    ReadingTheme(name: '護眼', backgroundColor: Color(0xFFC7EDCC), textColor: Color(0xFF2D4A32)),
    ReadingTheme(name: '夜間', backgroundColor: Color(0xFF1A1A2E), textColor: Color(0xFFB0B0B0)),
  ];
}

/// ReadingTheme - 閱讀排版配置模型
/// 高度還原 Android ReadBookConfig.Config 類別
class ReadingTheme {
  final String name;
  final Color backgroundColor;
  final Color textColor;
  
  // 核心排版屬性 (對標 Android Config 屬性)
  final double textSize;
  final double lineSpacing;
  final double paragraphSpacing;
  final double letterSpacing;
  final String paragraphIndent;
  final EdgeInsets padding;
  final int titleMode; // 0:左, 1:中, 2:隱藏
  final double titleSize;
  final String? fontFamily;
  final String? backgroundImage;

  const ReadingTheme({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    this.textSize = 18.0,
    this.lineSpacing = 1.5,
    this.paragraphSpacing = 1.0,
    this.letterSpacing = 0.0,
    this.paragraphIndent = "　　",
    this.padding = const EdgeInsets.all(16.0),
    this.titleMode = 1,
    this.titleSize = 22.0,
    this.fontFamily,
    this.backgroundImage,
  });

  factory ReadingTheme.fromJson(Map<String, dynamic> json) {
    return ReadingTheme(
      name: json['name'] ?? '未命名',
      backgroundColor: Color(int.parse(json['backgroundColor'] ?? '0xFFFFFFFF')),
      textColor: Color(int.parse(json['textColor'] ?? '0xFF1A1A1A')),
      textSize: (json['textSize'] ?? 18.0).toDouble(),
      lineSpacing: (json['lineSpacing'] ?? 1.5).toDouble(),
      paragraphSpacing: (json['paragraphSpacing'] ?? 1.0).toDouble(),
      letterSpacing: (json['letterSpacing'] ?? 0.0).toDouble(),
      paragraphIndent: json['paragraphIndent'] ?? "　　",
      padding: EdgeInsets.fromLTRB(
        (json['paddingLeft'] ?? 16.0).toDouble(),
        (json['paddingTop'] ?? 16.0).toDouble(),
        (json['paddingRight'] ?? 16.0).toDouble(),
        (json['paddingBottom'] ?? 16.0).toDouble(),
      ),
      titleMode: json['titleMode'] ?? 1,
      titleSize: (json['titleSize'] ?? 22.0).toDouble(),
      fontFamily: json['fontFamily'],
      backgroundImage: json['backgroundImage'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'backgroundColor': '0x${backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
    'textColor': '0x${textColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
    'textSize': textSize,
    'lineSpacing': lineSpacing,
    'paragraphSpacing': paragraphSpacing,
    'letterSpacing': letterSpacing,
    'paragraphIndent': paragraphIndent,
    'paddingLeft': padding.left,
    'paddingTop': padding.top,
    'paddingRight': padding.right,
    'paddingBottom': padding.bottom,
    'titleMode': titleMode,
    'titleSize': titleSize,
    'fontFamily': fontFamily,
    'backgroundImage': backgroundImage,
  };
}
