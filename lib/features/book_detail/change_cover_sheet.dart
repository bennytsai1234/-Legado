import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/search_book.dart';
import 'change_cover_provider.dart';
import 'book_detail_provider.dart';

class ChangeCoverSheet extends StatefulWidget {
  final String bookName;
  final String author;

  const ChangeCoverSheet({
    super.key,
    required this.bookName,
    required this.author,
  });

  @override
  State<ChangeCoverSheet> createState() => _ChangeCoverSheetState();
}

class _ChangeCoverSheetState extends State<ChangeCoverSheet> {
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final coverProvider = context.read<ChangeCoverProvider>();
      coverProvider.search(widget.bookName, widget.author);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        // 在此專案中，customCoverUrl 可以是檔案路徑或網路 URL
        // 閱讀器端應處理 file:// 協議或直接判斷
        context.read<BookDetailProvider>().updateCover('file://${image.path}');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('選取圖片失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildSearchBar(),
          const SizedBox(height: 8),
          _buildProgressIndicator(),
          Expanded(child: _buildCoverGrid()),
          _buildManualInputSection(),
          const SizedBox(height: 20),
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
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '更換封面',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<ChangeCoverProvider>().search(widget.bookName, widget.author);
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '搜尋關鍵字: ${widget.bookName} ${widget.author}',
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Consumer<ChangeCoverProvider>(
      builder: (context, provider, child) {
        if (!provider.isSearching && provider.covers.isNotEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            LinearProgressIndicator(value: provider.progress),
            const SizedBox(height: 4),
            Text(
              provider.isSearching ? '正在搜尋封面...' : '搜尋完成',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCoverGrid() {
    return Consumer<ChangeCoverProvider>(
      builder: (context, provider, child) {
        if (provider.covers.isEmpty && !provider.isSearching) {
          return const Center(child: Text('未找到相關封面'));
        }

        return GridView.builder(
          padding: const EdgeInsets.only(top: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemCount: provider.covers.length,
          itemBuilder: (context, index) {
            final book = provider.covers[index];
            return _buildCoverItem(book);
          },
        );
      },
    );
  }

  Widget _buildCoverItem(SearchBook book) {
    return GestureDetector(
      onTap: () {
        context.read<BookDetailProvider>().updateCover(book.coverUrl ?? '');
        Navigator.pop(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: book.coverUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.originName ?? '未知來源',
            style: const TextStyle(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildManualInputSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: '輸入封面 URL',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (_urlController.text.isNotEmpty) {
                context.read<BookDetailProvider>().updateCover(_urlController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('確定'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickImage,
            tooltip: '從相簿選取',
          ),
        ],
      ),
    );
  }
}
