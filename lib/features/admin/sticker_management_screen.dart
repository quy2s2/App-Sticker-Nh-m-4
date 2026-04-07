import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/database/app_database.dart';

class StickerManagementScreen extends StatefulWidget {
  final int albumId;
  final String albumName;

  const StickerManagementScreen({
    super.key,
    required this.albumId,
    required this.albumName,
  });

  @override
  State<StickerManagementScreen> createState() => _StickerManagementScreenState();
}

class _StickerManagementScreenState extends State<StickerManagementScreen> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> stickers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStickers();
  }

  Future<void> _loadStickers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final data = await AppDatabase.instance.getStickersByAlbum(widget.albumId);
    if (!mounted) return;

    setState(() {
      stickers = data;
      _isLoading = false;
    });
  }

  Future<void> _addSticker() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final captionController = TextEditingController();
    String? caption;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm Sticker'),
        content: TextField(
          controller: captionController,
          decoration: const InputDecoration(labelText: 'Caption'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              caption = captionController.text.trim();
              Navigator.pop(context, true);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    captionController.dispose();
    if (result != true || caption == null || caption!.isEmpty) return;

    await AppDatabase.instance.insertSticker({
      'imagePath': image.path,
      'caption': caption,
      'albumId': widget.albumId,
    });

    if (!mounted) return;
    await _loadStickers();
  }

  Future<void> _editCaption(int id, String oldCaption) async {
    final controller = TextEditingController(text: oldCaption);
    String? result;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa caption'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              result = controller.text.trim();
              Navigator.pop(context, true);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (ok != true || result == null || result!.isEmpty) return;

    await AppDatabase.instance.updateSticker(id, {'caption': result});
    if (!mounted) return;
    await _loadStickers();
  }

  Future<void> _deleteSticker(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa sticker'),
        content: const Text('Bạn chắc chắn muốn xóa sticker này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AppDatabase.instance.deleteSticker(id);
    if (!mounted) return;
    await _loadStickers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Album: ${widget.albumName}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : stickers.isEmpty
              ? const Center(child: Text('Album chưa có sticker'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: stickers.length,
                  itemBuilder: (context, index) {
                    final s = stickers[index];
                    final path = s['imagePath'] as String;

                    return Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: File(path).existsSync()
                                ? Image.file(File(path), fit: BoxFit.cover)
                                : const Icon(Icons.broken_image),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s['caption'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editCaption(s['id'] as int, s['caption'] ?? '')),
                            IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () => _deleteSticker(s['id'] as int)),
                          ],
                        ),
                      ],
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(onPressed: _addSticker, child: const Icon(Icons.add)),
    );
  }
}
