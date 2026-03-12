import 'dart:async';
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
  double _rate = 0.5;
  String? _language;
  List<dynamic> _languages = [];
  Map<String, String>? _voice;

  VoidCallback? onComplete; // 讀完回調
  Timer? _sleepTimer;
  int _remainingMinutes = 0;

  bool get isPlaying => _isPlaying;
  int get remainingMinutes => _remainingMinutes;
  double get pitch => _pitch;
  double get volume => _volume;
  double get rate => _rate;
  String? get language => _language;
  List<dynamic> get languages => _languages;
  Map<String, String>? get voice => _voice;

  TTSService._internal() {
    _initTts();
  }

  Future<void> _initTts() async {
    // 啟用 iOS 背景播放模式 (高度還原 Android AudioPlayService 音訊焦點)
    await _flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.duckOthers,
      ],
      IosTextToSpeechAudioMode.voicePrompt,
    );

    _flutterTts.setStartHandler(() {
      _isPlaying = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      notifyListeners();
      if (onComplete != null) onComplete!();
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

  /// 設定睡眠定時 (高度還原 Android addTimer)
  void setSleepTimer(int minutes) {
    _remainingMinutes = minutes;
    _sleepTimer?.cancel();
    if (minutes > 0) {
      _sleepTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (_remainingMinutes > 0) {
          _remainingMinutes--;
          notifyListeners();
        } else {
          stop();
          timer.cancel();
        }
      });
    }
    notifyListeners();
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
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    super.dispose();
  }
}

final ttsService = TTSService();
