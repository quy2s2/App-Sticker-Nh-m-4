import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/database/app_database.dart';
import 'sticker_management_screen.dart';

class AlbumManagementScreen extends StatefulWidget {
  const AlbumManagementScreen({super.key});

  @override
  State<AlbumManagementScreen> createState() => _AlbumManagementScreenState();
}

class _AlbumManagementScreenState extends State<AlbumManagementScreen> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> albums = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final data = await AppDatabase.instance.getAllAlbums();
    if (!mounted) return;

    setState(() {
      albums = data;
      _isLoading = false;
    });
  }

  Future<void> _showAlbumDialog({Map<String, dynamic>? album}) async {
    final nameController = TextEditingController(text: album?['name'] ?? '');
    String? coverPath = album?['coverImage'];

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(album == null ? 'Thêm Album' : 'Sửa Album'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setDialogState(() => coverPath = image.path);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: coverPath != null && File(coverPath!).existsSync()
                      ? Image.file(
                          File(coverPath!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 120,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.photo_album, size: 48),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên album'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    final name = nameController.text.trim();
    nameController.dispose();
    if (result != true || name.isEmpty) return;

    if (album == null) {
      await AppDatabase.instance.insertAlbum({
        'name': name,
        'coverImage': coverPath,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } else {
      await AppDatabase.instance.deleteAlbum(album['id']);
      await AppDatabase.instance.insertAlbum({
        'name': name,
        'coverImage': coverPath,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    if (!mounted) return;
    await _loadAlbums();
  }

  Future<void> _deleteAlbum(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa album'),
        content: const Text('Xóa album sẽ xóa luôn sticker bên trong.'),
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

    await AppDatabase.instance.deleteAlbum(id);
    if (!mounted) return;
    await _loadAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Album Sticker')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : albums.isEmpty
              ? const Center(child: Text('Chưa có album nào'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: albums.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final album = albums[index];
                    final cover = album['coverImage'];

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StickerManagementScreen(
                            albumId: album['id'],
                            albumName: album['name'],
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: cover != null && File(cover).existsSync()
                                  ? Image.file(File(cover), fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.photo_album, size: 48),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(album['name'], maxLines: 1, overflow: TextOverflow.ellipsis),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showAlbumDialog(album: album)),
                              IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () => _deleteAlbum(album['id'])),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAlbumDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
