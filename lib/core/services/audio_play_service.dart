import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

/// AudioPlayService - 音頻播放服務
class AudioPlayService extends ChangeNotifier {
  static final AudioPlayService _instance = AudioPlayService._internal();
  factory AudioPlayService() => _instance;
  AudioPlayService._internal() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  AudioPlayer get player => _player;

  Future<void> _init() async {
    if (_isInitialized) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _isInitialized = true;
  }

  Future<void> playUrl(String url, {String? title, String? artist, String? album, String? artUri}) async {
    try {
      await _init();
      // 使用 Lock 確保不會同時載入
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: url,
            album: album ?? "Legado Reader",
            title: title ?? "Unknown Chapter",
            artist: artist ?? "Unknown Author",
            artUri: artUri != null ? Uri.parse(artUri) : null,
          ),
        ),
      );
      _player.play();
    } catch (e) {
      debugPrint("AudioPlayService play error: $e");
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

// 模擬 MediaItem (如果沒引用 audio_service 套件)
class MediaItem {
  final String id;
  final String album;
  final String title;
  final String artist;
  final Uri? artUri;

  MediaItem({
    required this.id,
    required this.album,
    required this.title,
    required this.artist,
    this.artUri,
  });
}
