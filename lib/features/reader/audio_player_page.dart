import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/models/book_source.dart';
import '../../core/services/book_source_service.dart';
import '../../core/services/audio_play_service.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/database/dao/chapter_dao.dart';
import 'change_chapter_source_sheet.dart';

class AudioPlayerPage extends StatefulWidget {
  final Book book;
  final int chapterIndex;

  const AudioPlayerPage({super.key, required this.book, this.chapterIndex = 0});

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  late int _currentChapterIndex;
  List<BookChapter> _chapters = [];
  BookSource? _source;
  
  final AudioPlayService _audioService = AudioPlayService();
  final BookSourceService _service = BookSourceService();
  final BookSourceDao _sourceDao = BookSourceDao();
  final ChapterDao _chapterDao = ChapterDao();

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.chapterIndex;
    _init();
  }

  Future<void> _init() async {
    _chapters = await _chapterDao.getChapters(widget.book.bookUrl);
    final sources = await _sourceDao.getAll();
    _source = sources.cast<BookSource?>().firstWhere(
      (s) => s?.bookSourceUrl == widget.book.origin,
      orElse: () => null,
    );
    _loadChapter(_currentChapterIndex);
  }

  Future<void> _loadChapter(int index) async {
    if (_source == null) return;
    setState(() => _currentChapterIndex = index);

    try {
      final audioUrl = await _service.getContent(_source!, widget.book, _chapters[index]);
      await _audioService.playUrl(
        audioUrl,
        title: _chapters[index].title,
        artist: widget.book.author,
        album: widget.book.name,
        artUri: widget.book.coverUrl,
      );
    } catch (e) {
      debugPrint("Load audio chapter error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _audioService,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("有聲播放"),
            actions: [
              IconButton(
                icon: const Icon(Icons.swap_horiz), 
                onPressed: _showChangeSource,
                tooltip: '換源',
              ),
              IconButton(icon: const Icon(Icons.timer_outlined), onPressed: _showTimerDialog),
              IconButton(icon: const Icon(Icons.list), onPressed: _showToc),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _buildMainPlayer()),
              _buildBottomInfo(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainPlayer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: widget.book.bookUrl,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: widget.book.coverUrl ?? "",
                width: 200,
                height: 280,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.book, size: 100),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(widget.book.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(_chapters.isNotEmpty ? _chapters[_currentChapterIndex].title : "", 
            style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 40),
          
          StreamBuilder<Duration>(
            stream: _audioService.player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _audioService.player.duration ?? Duration.zero;
              return Column(
                children: [
                  Slider(
                    value: position.inMilliseconds.toDouble(),
                    max: duration.inMilliseconds.toDouble().clamp(0, double.infinity),
                    onChanged: (v) => _audioService.seek(Duration(milliseconds: v.toInt())),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: const TextStyle(fontSize: 12)),
                        Text(_formatDuration(duration), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 32,
                icon: _getPlayModeIcon(),
                onPressed: _audioService.nextPlayMode,
                tooltip: '播放模式',
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 48,
                icon: const Icon(Icons.skip_previous),
                onPressed: _currentChapterIndex > 0 ? () => _loadChapter(_currentChapterIndex - 1) : null,
              ),
              StreamBuilder<PlayerState>(
                stream: _audioService.player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  final processingState = snapshot.data?.processingState;
                  if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    );
                  }
                  return GestureDetector(
                    onLongPress: () {
                      _audioService.stop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('停止播放')));
                      }
                    },
                    child: IconButton(
                      iconSize: 72,
                      icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                      onPressed: playing ? _audioService.pause : _audioService.resume,
                    ),
                  );
                },
              ),
              IconButton(
                iconSize: 48,
                icon: const Icon(Icons.skip_next),
                onPressed: _currentChapterIndex < _chapters.length - 1 ? () => _loadChapter(_currentChapterIndex + 1) : null,
              ),
              const SizedBox(width: 16),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.speed),
                onPressed: _showSpeedDialog,
                tooltip: '播放速度',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Icon _getPlayModeIcon() {
    switch (_audioService.playMode) {
      case AudioPlayMode.listLoop: return const Icon(Icons.repeat);
      case AudioPlayMode.singleLoop: return const Icon(Icons.repeat_one);
      case AudioPlayMode.shuffle: return const Icon(Icons.shuffle);
      case AudioPlayMode.listEndStop: return const Icon(Icons.trending_flat);
    }
  }

  Widget _buildBottomInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_audioService.remainingSleepTime != null)
            Row(
              children: [
                const Icon(Icons.timer_sharp, size: 18, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  '定時關閉：${_formatDuration(_audioService.remainingSleepTime!)}',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ],
            )
          else
            const Text('定時關閉已禁用', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds";
  }

  void _showToc() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: _chapters.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_chapters[index].title, 
            style: TextStyle(color: index == _currentChapterIndex ? Colors.blue : null)),
          onTap: () {
            Navigator.pop(context);
            _loadChapter(index);
          },
        ),
      ),
    );
  }

  void _showChangeSource() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeChapterSourceSheet(
        book: widget.book,
        chapterIndex: _currentChapterIndex,
        chapterTitle: _chapters.isNotEmpty ? _chapters[_currentChapterIndex].title : "未知章節",
      ),
    );
  }

  void _showTimerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('定時睡眠 (分鐘)', style: TextStyle(fontWeight: FontWeight.bold))),
          _timerOption(0, '關閉'),
          _timerOption(15, '15 分鐘'),
          _timerOption(30, '30 分鐘'),
          _timerOption(60, '60 分鐘'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _timerOption(int min, String label) {
    return ListTile(
      title: Text(label),
      onTap: () {
        _audioService.setSleepTimer(min);
        Navigator.pop(context);
      },
    );
  }

  void _showSpeedDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text('播放速度', style: TextStyle(fontWeight: FontWeight.bold))),
          _speedOption(0.8),
          _speedOption(1.0),
          _speedOption(1.2),
          _speedOption(1.5),
          _speedOption(2.0),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _speedOption(double speed) {
    return ListTile(
      title: Text('${speed.toStringAsFixed(1)}x'),
      onTap: () {
        _audioService.player.setSpeed(speed);
        Navigator.pop(context);
      },
    );
  }
}
