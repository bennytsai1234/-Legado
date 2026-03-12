import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/models/book_source.dart';
import '../../core/services/book_source_service.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/database/dao/chapter_dao.dart';

class MangaReaderPage extends StatefulWidget {
  final Book book;
  final int chapterIndex;

  const MangaReaderPage({super.key, required this.book, this.chapterIndex = 0});

  @override
  State<MangaReaderPage> createState() => _MangaReaderPageState();
}

class _MangaReaderPageState extends State<MangaReaderPage> {
  late int _currentChapterIndex;
  List<String> _imageUrls = [];
  bool _isLoading = true;
  List<BookChapter> _chapters = [];
  BookSource? _source;
  bool _showControls = true;
  double _brightness = 1.0;

  final BookSourceService _service = BookSourceService();
  final BookSourceDao _sourceDao = BookSourceDao();
  final ChapterDao _chapterDao = ChapterDao();

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.chapterIndex;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _init();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _init() async {
    _chapters = await _chapterDao.getChapters(widget.book.bookUrl);
    _source = await _sourceDao.getByUrl(widget.book.origin);
    _loadChapter(_currentChapterIndex);
  }

  Future<void> _loadChapter(int index) async {
    if (_source == null) return;
    setState(() {
      _isLoading = true;
      _currentChapterIndex = index;
    });

    try {
      final content = await _service.getContent(_source!, widget.book, _chapters[index]);
      // 漫畫內容通常是圖片 URL 列表 (換行或逗號分隔)
      _imageUrls = content.split(RegExp(r'[\n\r,]+')).where((e) => e.trim().isNotEmpty).toList();
    } catch (e) {
      debugPrint("Load manga chapter error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 內容層
          GestureDetector(
            onTap: _toggleControls,
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 5.0,
                  child: ListView.builder(
                    itemCount: _imageUrls.length,
                    cacheExtent: 1000, // 預加載圖片
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: _imageUrls[index],
                        placeholder: (context, url) => Container(
                          height: 400,
                          color: Colors.black,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: Colors.grey[900],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.white),
                              Text("圖片加載失敗", style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        fit: BoxFit.fitWidth,
                      );
                    },
                  ),
                ),
          ),

          // 頂部工具列
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // 底部工具列
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: _showControls ? 0 : -120,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),

          // 亮度覆蓋
          if (_brightness < 1.0)
            IgnorePointer(
              child: Container(color: Colors.black.withValues(alpha: 1.0 - _brightness)),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topPadding),
      color: Colors.black.withValues(alpha: 0.85),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.book.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
            Text(_chapters.isNotEmpty ? _chapters[_currentChapterIndex].title : "", 
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: _showToc,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 8),
      color: Colors.black.withValues(alpha: 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.brightness_6, color: Colors.white70, size: 18),
              Expanded(
                child: Slider(
                  value: _brightness,
                  min: 0.1,
                  max: 1.0,
                  onChanged: (v) => setState(() => _brightness = v),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _currentChapterIndex > 0 ? () => _loadChapter(_currentChapterIndex - 1) : null,
                child: const Text("上一章", style: TextStyle(color: Colors.white)),
              ),
              Text("${_currentChapterIndex + 1} / ${_chapters.length}", 
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _currentChapterIndex < _chapters.length - 1 ? () => _loadChapter(_currentChapterIndex + 1) : null,
                child: const Text("下一章", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showToc() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const Text("目錄", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: _chapters.length,
                itemBuilder: (context, index) => ListTile(
                  dense: true,
                  title: Text(_chapters[index].title, 
                    style: TextStyle(color: index == _currentChapterIndex ? Colors.blue : Colors.white70)),
                  onTap: () {
                    Navigator.pop(context);
                    _loadChapter(index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
