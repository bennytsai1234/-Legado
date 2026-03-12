import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/book.dart';
import '../../core/models/book_source.dart';
import '../../core/models/chapter.dart';
import '../../core/models/search_book.dart';
import '../../core/services/book_source_service.dart';
import '../../core/database/dao/book_source_dao.dart';
import '../../core/database/dao/search_book_dao.dart';
import 'reader_provider.dart';
import 'reader_page.dart';
import 'audio_player_page.dart';

class ChangeChapterSourceSheet extends StatefulWidget {
  final Book book;
  final int chapterIndex;
  final String chapterTitle;

  const ChangeChapterSourceSheet({
    super.key,
    required this.book,
    required this.chapterIndex,
    required this.chapterTitle,
  });

  @override
  State<ChangeChapterSourceSheet> createState() => _ChangeChapterSourceSheetState();
}

class _ChangeChapterSourceSheetState extends State<ChangeChapterSourceSheet> {
  final BookSourceService _service = BookSourceService();
  final BookSourceDao _sourceDao = BookSourceDao();
  final SearchBookDao _searchBookDao = SearchBookDao();
  final TextEditingController _filterController = TextEditingController();
  
  List<SearchBook> _allResults = [];
  List<SearchBook> _filteredResults = [];
  List<String> _groups = ['全部'];
  String _selectedGroup = '全部';
  bool _isSearching = false;
  String _status = "正在初始化...";
  bool _checkAuthor = true;

  @override
  void initState() {
    super.initState();
    _loadGroups().then((_) => _startSearch());
  }

  Future<void> _loadGroups() async {
    final sources = await _sourceDao.getEnabled();
    final Set<String> groupSet = {'全部'};
    for (var s in sources) {
      if (s.bookSourceGroup != null && s.bookSourceGroup!.isNotEmpty) {
        groupSet.addAll(s.bookSourceGroup!.split(',').map((e) => e.trim()));
      }
    }
    if (mounted) {
      setState(() {
        _groups = groupSet.toList()..sort();
      });
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _applyFilter(String key) {
    setState(() {
      if (key.isEmpty) {
        _filteredResults = _allResults;
      } else {
        final query = key.toLowerCase();
        _filteredResults = _allResults.where((r) => 
          (r.originName ?? "").toLowerCase().contains(query) || 
          (r.latestChapterTitle ?? "").toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  int _getChapterNum(String? title) {
    if (title == null || title.isEmpty) return 0;
    final match = RegExp(r'\[(\d+)]').firstMatch(title);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 0;
  }

  Future<void> _startSearch() async {
    // 1. 預加載快取 (對應 Android getDbSearchBooks)
    final cached = await _searchBookDao.getSearchBooks(widget.book.name, widget.book.author);
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _allResults = cached;
        _applyFilter(_filterController.text);
        _status = "載入快取來源... 正在同步更新...";
      });
    }

    setState(() {
      _isSearching = true;
      if (_allResults.isEmpty) _status = "正在搜尋可用書源...";
    });

    try {
      var enabledSources = await _sourceDao.getEnabled();
      
      // 深度還原：套用分組過濾邏輯 (對標 Android searchGroup)
      if (_selectedGroup != '全部') {
        enabledSources = enabledSources.where((s) {
          final g = s.bookSourceGroup ?? "";
          return g.split(',').map((e) => e.trim()).contains(_selectedGroup);
        }).toList();
      }

      var results = await _service.preciseSearch(
        enabledSources, 
        widget.book.name, 
        _checkAuthor ? widget.book.author : ""
      );
      
      // 深度補齊：對齊 Android 優選邏輯 (ChangeBookSourceViewModel.kt)
      results.sort((a, b) {
        // 1. 比較書源自定義排序
        int cmp = a.originOrder.compareTo(b.originOrder);
        if (cmp != 0) return cmp;
        
        // 2. 比較最新章節序號 (如 [123] 第123章)
        final aNum = _getChapterNum(a.latestChapterTitle);
        final bNum = _getChapterNum(b.latestChapterTitle);
        if (aNum != bNum) return bNum.compareTo(aNum);
        
        // 3. 比較最新章節資訊存在性
        final aHasToc = a.latestChapterTitle != null && a.latestChapterTitle!.isNotEmpty;
        final bHasToc = b.latestChapterTitle != null && b.latestChapterTitle!.isNotEmpty;
        if (aHasToc != bHasToc) return aHasToc ? -1 : 1;
        
        return 0;
      });

      if (mounted) {
        setState(() {
          _allResults = results;
          _applyFilter(_filterController.text);
          _isSearching = false;
          _status = results.isEmpty ? "未找到備用書源" : "搜尋完成 (已自動優選)";
        });

        // 深度還原：空結果引導邏輯 (對標 Android searchFinishCallback)
        if (results.isEmpty && _selectedGroup != '全部') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('分組「$_selectedGroup」下無結果，是否切換至全部？'),
              action: SnackBarAction(
                label: '切換',
                onPressed: () {
                  setState(() => _selectedGroup = '全部');
                  _startSearch();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _status = "搜尋出錯: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildFilterBar(),
          if (_isSearching) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_status, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(child: _buildSourceList()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('單章換源', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('目標章節: ${widget.chapterTitle}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_checkAuthor ? Icons.person : Icons.person_off),
            tooltip: _checkAuthor ? '檢核作者' : '不檢核作者',
            onPressed: () {
              setState(() => _checkAuthor = !_checkAuthor);
              _startSearch();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _startSearch),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Column(
      children: [
        if (_groups.length > 1)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _groups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, index) {
                final group = _groups[index];
                final isSelected = _selectedGroup == group;
                return FilterChip(
                  label: Text(group, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _selectedGroup = group);
                    _startSearch();
                  },
                  selectedColor: Colors.blue,
                  showCheckmark: false,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _filterController,
            decoration: InputDecoration(
              hintText: '搜尋結果內篩選...',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: _applyFilter,
          ),
        ),
      ],
    );
  }

  Widget _buildSourceList() {
    if (_filteredResults.isEmpty && !_isSearching) {
      return const Center(child: Text('無搜尋結果'));
    }

    return ListView.separated(
      itemCount: _filteredResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final res = _filteredResults[index];
        return ListTile(
          title: Text(res.originName ?? "未知來源"),
          subtitle: Text(res.latestChapterTitle ?? "無最新章節資訊", maxLines: 1),
          onTap: () => _handleSourceSelected(res),
        );
      },
    );
  }

  Future<void> _handleSourceSelected(SearchBook searchBook) async {
    final sources = await _sourceDao.getAll();
    final source = sources.cast<BookSource?>().firstWhere((s) => s?.bookSourceUrl == searchBook.origin, orElse: () => null);
    if (source == null) return;

    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tempBook = searchBook.toBook();
      final chapters = await _service.getChapterList(source, tempBook);
      
      int targetIndex = -1;
      for (int i = 0; i < chapters.length; i++) {
        if (chapters[i].title == widget.chapterTitle) {
          targetIndex = i;
          break;
        }
      }
      if (targetIndex == -1 && widget.chapterIndex < chapters.length) {
        targetIndex = widget.chapterIndex;
      }

      if (targetIndex != -1) {
        final content = await _service.getContent(source, tempBook, chapters[targetIndex]);
        
        if (mounted) {
          Navigator.pop(context); // 關閉 Loading
          
          if (tempBook.type != widget.book.type) {
            final migratedBook = widget.book.migrateTo(tempBook);
            migratedBook.isInBookshelf = widget.book.isInBookshelf;
            _showMigrationDialog(context, migratedBook);
          } else {
            context.read<ReaderProvider>().replaceChapterSource(widget.chapterIndex, source, content);
            Navigator.pop(context); // 關閉 Sheet
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已替換自來源: ${source.bookSourceName}')));
          }
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('在該來源中找不到對應章節')));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('換源失敗: $e')));
      }
    }
  }

  void _showMigrationDialog(BuildContext context, Book newBook) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('書籍類型變更'),
        content: Text('偵測到新來源為${newBook.type == 2 ? "有聲" : "文本"}類型，是否執行遷移並跳轉？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              
              if (newBook.type == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => AudioPlayerPage(book: newBook, chapterIndex: newBook.durChapterIndex)),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ReaderPage(book: newBook)),
                );
              }
            },
            child: const Text('遷移並跳轉'),
          ),
        ],
      ),
    );
  }
}
