import 'package:flutter/material.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';

class ReaderSettingsSheets {
  static void showPageTurnMode(BuildContext context, ReaderProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('翻頁模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioTile(context, "無動畫", 0, provider.pageTurnMode, provider.setPageTurnMode),
            _buildRadioTile(context, "覆蓋 (Horizontal)", 1, provider.pageTurnMode, provider.setPageTurnMode),
            _buildRadioTile(context, "滾動 (Vertical)", 2, provider.pageTurnMode, provider.setPageTurnMode),
            _buildRadioTile(context, "仿真 (Simulation)", 3, provider.pageTurnMode, provider.setPageTurnMode),
          ],
        ),
      ),
    );
  }

  static void showTypography(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSliderRow("字體大小", provider.fontSize, 14, 30, provider.setFontSize),
              _buildSliderRow("行高", provider.lineHeight, 1.2, 2.5, provider.setLineHeight),
              _buildSliderRow("段落間距", provider.paragraphSpacing, 0, 5, provider.setParagraphSpacing),
              _buildSliderRow("字間距", provider.letterSpacing, -1, 5, provider.setLetterSpacing),
            ],
          ),
        ),
      ),
    );
  }

  static void showTheme(BuildContext context, ReaderProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AppTheme.readingThemes.length,
            itemBuilder: (context, index) {
              final theme = AppTheme.readingThemes[index];
              return GestureDetector(
                onTap: () => provider.setTheme(index),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: provider.themeIndex == index ? Colors.blue : Colors.grey,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "Aa",
                      style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static Widget _buildSliderRow(String label, double value, double min, double max, Function(double) onChanged) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Expanded(child: Slider(value: value, min: min, max: max, onChanged: onChanged)),
        Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  static Widget _buildRadioTile(BuildContext context, String label, int value, int groupValue, Function(int) onChanged) {
    return RadioListTile<int>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (v) {
        if (v != null) onChanged(v);
        Navigator.pop(context);
      },
    );
  }
}
