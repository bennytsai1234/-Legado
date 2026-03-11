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
    return Scaffold(
      appBar: AppBar(
        title: const Text("有聲閱讀"),
        actions: [
          IconButton(icon: const Icon(Icons.list), onPressed: _showToc),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 封面
            Hero(
              tag: widget.book.bookUrl,
              child: Container(
                width: 200,
                height: 280,
                decoration: BoxDecoration(
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.book.coverUrl ?? "",
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
            
            // 進度條
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // 控制按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                    return IconButton(
                      iconSize: 64,
                      icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                      onPressed: playing ? _audioService.pause : _audioService.resume,
                    );
                  },
                ),
                IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.skip_next),
                  onPressed: _currentChapterIndex < _chapters.length - 1 ? () => _loadChapter(_currentChapterIndex + 1) : null,
                ),
              ],
            ),
          ],
        ),
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
}
