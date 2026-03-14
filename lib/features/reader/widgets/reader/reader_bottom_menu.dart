import 'package:flutter/material.dart';
import '../../reader_provider.dart';

class ReaderBottomMenu extends StatelessWidget {
  final ReaderProvider provider;
  final VoidCallback onOpenDrawer;
  final VoidCallback onTts;
  final VoidCallback onInterface;
  final VoidCallback onSettings;
  final VoidCallback onAutoPage;
  final VoidCallback onToggleDayNight;

  const ReaderBottomMenu({
    super.key, required this.provider, required this.onOpenDrawer, 
    required this.onTts, required this.onInterface, required this.onSettings, 
    required this.onAutoPage, required this.onToggleDayNight
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: provider.showControls ? 0 : -200,
      left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
        color: Colors.black.withValues(alpha: 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQuickActions(),
            const SizedBox(height: 12),
            _buildPrimaryActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _menuIcon(Icons.list, '目錄', onOpenDrawer),
        _menuIcon(Icons.record_voice_over, '朗讀', onTts),
        _menuIcon(Icons.color_lens, '介面', onInterface),
        _menuIcon(Icons.settings, '設定', onSettings),
      ],
    );
  }

  Widget _buildPrimaryActions() {
    return Row(
      children: [
        IconButton(icon: Icon(provider.isAutoPaging ? Icons.pause : Icons.play_arrow, color: Colors.white), onPressed: onAutoPage),
        const Spacer(),
        IconButton(icon: Icon(provider.themeIndex == 1 ? Icons.wb_sunny : Icons.nightlight_round, color: Colors.white), onPressed: onToggleDayNight),
      ],
    );
  }

  Widget _menuIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}
