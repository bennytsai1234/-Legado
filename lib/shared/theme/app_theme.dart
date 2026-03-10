/// App Theme - 主題配置
/// 定義全域色彩、文字樣式、元件主題
library;

import 'package:flutter/material.dart';

class AppTheme {
  // === Color Palette ===
  static const Color primaryColor = Color(0xFF5B7FFF);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color accentColor = Color(0xFF06B6D4);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFEF4444);

  // Dark
  static const Color darkSurfaceColor = Color(0xFF1E293B);
  static const Color darkBackgroundColor = Color(0xFF0F172A);

  // === Light Theme ===
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: 4,
    ),
  );

  // === Dark Theme ===
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: primaryColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // === Reading Themes ===
  static const List<ReadingTheme> readingThemes = [
    ReadingTheme(
      name: '預設',
      backgroundColor: Color(0xFFFFFFFF),
      textColor: Color(0xFF1A1A1A),
    ),
    ReadingTheme(
      name: '護眼',
      backgroundColor: Color(0xFFC7EDCC),
      textColor: Color(0xFF2D4A32),
    ),
    ReadingTheme(
      name: '羊皮紙',
      backgroundColor: Color(0xFFF5E6C8),
      textColor: Color(0xFF4A3728),
    ),
    ReadingTheme(
      name: '夜間',
      backgroundColor: Color(0xFF1A1A2E),
      textColor: Color(0xFFB0B0B0),
    ),
    ReadingTheme(
      name: '墨黑',
      backgroundColor: Color(0xFF000000),
      textColor: Color(0xFF808080),
    ),
  ];
}

/// Reading theme configuration
class ReadingTheme {
  final String name;
  final Color backgroundColor;
  final Color textColor;

  const ReadingTheme({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
  });
}
