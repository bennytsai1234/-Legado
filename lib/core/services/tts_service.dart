import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// TTSService - TTS 朗讀服務
/// 對應 Android: service/TTSReadAloudService.kt
class TTSService extends ChangeNotifier {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();

  bool _isPlaying = false;
  double _pitch = 1.0;
  double _volume = 1.0;
  double _rate = 0.5; // flutter_tts default rate is around 0.5
  String? _language;
  List<dynamic> _languages = [];

  bool get isPlaying => _isPlaying;
  double get pitch => _pitch;
  double get volume => _volume;
  double get rate => _rate;
  String? get language => _language;
  List<dynamic> get languages => _languages;

  TTSService._internal() {
    _initTts();
  }

  Future<void> _initTts() async {
    _flutterTts.setStartHandler(() {
      _isPlaying = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      notifyListeners();
    });

    _flutterTts.setCancelHandler(() {
      _isPlaying = false;
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
      debugPrint("TTS Error: $msg");
      notifyListeners();
    });

    _languages = await _flutterTts.getLanguages;
    if (_languages.isNotEmpty) {
      _language = _languages.first.toString();
      await _flutterTts.setLanguage(_language!);
    }
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _flutterTts.setLanguage(lang);
    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _flutterTts.setPitch(pitch);
    notifyListeners();
  }

  Future<void> setRate(double rate) async {
    _rate = rate;
    await _flutterTts.setSpeechRate(rate);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _flutterTts.setVolume(volume);
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _isPlaying = false;
    notifyListeners();
  }
}
