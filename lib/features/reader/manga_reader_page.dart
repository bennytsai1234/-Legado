import 'package:flutter/material.dart';
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        title: Text(_chapters.isNotEmpty ? _chapters[_currentChapterIndex].title : widget.book.name, 
          style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            onPressed: _showToc,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: ListView.builder(
              itemCount: _imageUrls.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: _imageUrls[index],
                  placeholder: (context, url) => Container(
                    height: 300,
                    color: Colors.grey[900],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[900],
                    child: const Icon(Icons.broken_image, color: Colors.white),
                  ),
                  fit: BoxFit.fitWidth,
                );
              },
            ),
          ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: _currentChapterIndex > 0 ? () => _loadChapter(_currentChapterIndex - 1) : null,
            child: const Text("上一章", style: TextStyle(color: Colors.white)),
          ),
          Text("${_currentChapterIndex + 1} / ${_chapters.length}", 
            style: const TextStyle(color: Colors.white70)),
          TextButton(
            onPressed: _currentChapterIndex < _chapters.length - 1 ? () => _loadChapter(_currentChapterIndex + 1) : null,
            child: const Text("下一章", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showToc() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => ListView.builder(
        itemCount: _chapters.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(_chapters[index].title, 
            style: TextStyle(color: index == _currentChapterIndex ? Colors.blue : Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _loadChapter(index);
          },
        ),
      ),
    );
  }
}
