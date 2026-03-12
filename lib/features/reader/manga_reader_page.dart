import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
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

class _MangaReaderPageState extends State<MangaReaderPage> with WidgetsBindingObserver {
  late int _currentChapterIndex;
  List<String> _imageUrls = [];
  bool _isLoading = true;
  List<BookChapter> _chapters = [];
  BookSource? _source;
  bool _showControls = true;
  double _brightness = 1.0;
  int _currentPage = 0; // 當前頁碼 (對標 Android durChapterPos)
  
  // 閱讀模式：0: 垂直, 1: 水平, 2: WebToon
  int _readingMode = 0; 
  Timer? _autoScrollTimer;
  bool _isAutoScrolling = false;
  double _autoScrollSpeed = 2.0;

  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  void _toggleAutoScroll() {
    if (_readingMode == 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("水平翻頁模式不支援自動捲動")));
      return;
    }
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
      _showControls = false;
    });
    
    if (_isAutoScrolling) {
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        if (_scrollController.hasClients) {
          final max = _scrollController.position.maxScrollExtent;
          final current = _scrollController.offset;
          if (current >= max) {
            _stopAutoScroll();
            if (_currentChapterIndex < _chapters.length - 1) {
              _loadChapter(_currentChapterIndex + 1);
            }
          } else {
            _scrollController.jumpTo(current + _autoScrollSpeed);
          }
        }
      });
    } else {
      _autoScrollTimer?.cancel();
    }
  }

  void _stopAutoScroll() {
    if (_isAutoScrolling) {
      setState(() => _isAutoScrolling = false);
      _autoScrollTimer?.cancel();
    }
  }
  final BookSourceService _service = BookSourceService();
  final BookSourceDao _sourceDao = BookSourceDao();
  final ChapterDao _chapterDao = ChapterDao();

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.chapterIndex;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _init();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_readingMode != 1) { // 垂直或 WebToon 模式
      // 根據捲動偏移量簡單估算頁碼 (對標 Android 邏輯)
      final pos = (_scrollController.offset / 600).floor();
      if (pos != _currentPage && pos < _imageUrls.length) {
        setState(() => _currentPage = pos);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // 深度還原：處理點擊區域 (對標 Android webtoonFrame.onTouchMiddle/onNextPage)
  void _handleTap(TapUpDetails details, double width) {
    final x = details.globalPosition.dx;
    if (x < width / 3) {
      _prevPage();
    } else if (x > width * 2 / 3) {
      _nextPage();
    } else {
      _toggleControls();
    }
  }

  void _nextPage() {
    if (_readingMode == 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    } else {
      _scrollController.animateTo(_scrollController.offset + 500, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_readingMode == 1) {
      _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    } else {
      _scrollController.animateTo(_scrollController.offset - 500, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    }
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 內容層：深度還原三段式區域點擊與模式切換
              GestureDetector(
                onTapUp: (details) => _handleTap(details, constraints.maxWidth),
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: _readingMode == 1 
                        ? PageView.builder(
                            controller: _pageController,
                            itemCount: _imageUrls.length,
                            onPageChanged: (idx) => setState(() => _currentPage = idx),
                            itemBuilder: (ctx, idx) => _buildMangaImage(idx),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _imageUrls.length,
                            cacheExtent: 2000,
                            padding: EdgeInsets.zero,
                            itemBuilder: (ctx, idx) => _buildMangaImage(idx),
                          ),
                    ),
              ),

              // 頁尾資訊條 (深度還原 Android InfoBar)
              if (!_showControls)
                Positioned(
                  bottom: 4, left: 0, right: 0,
                  child: _buildInfoBar(),
                ),

              // 頂部工具列
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                top: _showControls ? 0 : -100,
                left: 0, right: 0,
                child: _buildTopBar(),
              ),

              // 底部工具列
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                bottom: _showControls ? 0 : -150,
                left: 0, right: 0,
                child: _buildBottomBar(),
              ),

              // 亮度覆蓋
              if (_brightness < 1.0)
                IgnorePointer(
                  child: Container(color: Colors.black.withValues(alpha: 1.0 - _brightness)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMangaImage(int index) {
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
      fit: _readingMode == 2 ? BoxFit.fitWidth : BoxFit.contain,
    );
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_chapters.isNotEmpty ? _chapters[_currentChapterIndex].title : ""} (${_currentPage + 1}/${_imageUrls.length})',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          Row(
            children: [
              const Icon(Icons.battery_3_bar, color: Colors.white70, size: 10),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm').format(DateTime.now()),
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
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
              const Icon(Icons.chrome_reader_mode_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(_isAutoScrolling ? Icons.pause_circle_filled : Icons.play_circle_outline, color: Colors.blue),
                onPressed: _toggleAutoScroll,
                tooltip: '自動捲動',
              ),
              const Text("模式：", style: TextStyle(color: Colors.white, fontSize: 14)),
              DropdownButton<int>(
                dropdownColor: Colors.grey[900],
                value: _readingMode,
                items: const [
                  DropdownMenuItem(value: 0, child: Text("垂直捲動", style: TextStyle(color: Colors.white, fontSize: 13))),
                  DropdownMenuItem(value: 1, child: Text("水平翻頁", style: TextStyle(color: Colors.white, fontSize: 13))),
                  DropdownMenuItem(value: 2, child: Text("WebToon", style: TextStyle(color: Colors.white, fontSize: 13))),
                ],
                onChanged: (v) => setState(() => _readingMode = v!),
              ),
              const Spacer(),
              const Icon(Icons.brightness_6, color: Colors.white70, size: 18),
              SizedBox(
                width: 100,
                child: Slider(
                  value: _brightness,
                  min: 0.1, max: 1.0,
                  onChanged: (v) => setState(() => _brightness = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
