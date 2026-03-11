import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/http_tts.dart';
import '../engine/analyze_url.dart';
import '../engine/analyze_rule.dart';

class HttpTtsService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> speak(HttpTTS config, String text) async {
    try {
      // 替換文本佔位符 {{speakText}}
      final urlStr = config.url.replaceAll("{{speakText}}", Uri.encodeComponent(text));
      
      final analyzer = AnalyzeRule(source: config);
      final analyzeUrl = AnalyzeUrl(urlStr, analyzer: analyzer);
      
      // 如果 API 直接返回音頻流 URL，則播放之
      // 否則可能需要先獲取回應內容
      final audioUrl = analyzeUrl.url;
      
      await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      _player.play();
    } catch (e) {
      debugPrint("HTTP TTS Error: $e");
    }
  }

  void stop() => _player.stop();
}
