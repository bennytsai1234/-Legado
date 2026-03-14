import 'package:flutter/material.dart';
import 'package:legado_reader/features/reader/reader_provider.dart';

class ReaderBrightnessBar extends StatelessWidget {
  final ReaderProvider provider;

  const ReaderBrightnessBar({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      left: provider.showControls ? 10 : -60, // 在左側滑入滑出
      top: MediaQuery.of(context).size.height * 0.25,
      bottom: MediaQuery.of(context).size.height * 0.25,
      child: Container(
        width: 45,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Icon(Icons.brightness_7, color: Colors.white, size: 18),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3, // 旋轉為直立
                child: Slider(
                  value: provider.brightness,
                  onChanged: (v) => provider.setBrightness(v),
                  activeColor: Colors.blue,
                  inactiveColor: Colors.white24,
                ),
              ),
            ),
            const Icon(Icons.brightness_4, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
