import 'package:flutter/material.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';

class ReaderBrightnessBar extends StatelessWidget {
  final ReaderProvider provider;

  const ReaderBrightnessBar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: provider.showControls ? 120 : -100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const Icon(Icons.brightness_low, color: Colors.white, size: 20),
            Expanded(
              child: Slider(
                value: provider.brightness,
                onChanged: provider.setBrightness,
              ),
            ),
            const Icon(Icons.brightness_high, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
