import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';

class UserStickerScreen extends StatefulWidget {
  const UserStickerScreen({super.key, this.onStickerSelected});

  final Function(String)? onStickerSelected;

  @override
  State<UserStickerScreen> createState() => _UserStickerScreenState();
}

class _UserStickerScreenState extends State<UserStickerScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> albums = [];
  List<Map<String, dynamic>> stickers = [];

  int? selectedAlbumId;
  String? selectedAlbumName;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  /// ================= LOAD ALBUMS =================
  Future<void> _loadAlbums() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      selectedAlbumId = null;
      stickers.clear();
    });

    try {
      final data = await AppDatabase.instance.getAllAlbums();
      if (!mounted) return;

      setState(() {
        albums = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải album: $e';
        _isLoading = false;
      });
    }
  }

  /// ================= LOAD STICKERS BY ALBUM =================
  Future<void> _loadStickers(int albumId, String albumName) async {
    setState(() {
      _isLoading = true;
      selectedAlbumId = albumId;
      selectedAlbumName = albumName;
    });

    try {
      final data =
          await AppDatabase.instance.getStickersByAlbum(albumId);
      if (!mounted) return;

      setState(() {
        stickers = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải sticker: $e';
        _isLoading = false;
      });
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedAlbumId == null
              ? 'Chọn Album Sticker'
              : 'Album: $selectedAlbumName',
        ),
        backgroundColor: Colors.purpleAccent,
        leading: selectedAlbumId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _loadAlbums,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : selectedAlbumId == null
                  ? _buildAlbumGrid()
                  : _buildStickerGrid(),
    );
  }

  /// ================= ALBUM GRID =================
  Widget _buildAlbumGrid() {
    if (albums.isEmpty) {
      return const Center(
        child: Text('Chưa có album nào 😢'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: albums.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final album = albums[index];
        final cover = album['coverPath'] as String?;

        return InkWell(
          onTap: () => _loadStickers(
            album['id'] as int,
            album['name'] as String,
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
              Text(
                album['name'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ================= STICKER GRID =================
  Widget _buildStickerGrid() {
    if (stickers.isEmpty) {
      return const Center(
        child: Text('Album này chưa có sticker'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: stickers.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final sticker = stickers[index];
        final path = sticker['imagePath'] as String;

        return GestureDetector(
          onTap: () {
            widget.onStickerSelected?.call(path);
            Navigator.pop(context);
          },
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: File(path).existsSync()
                      ? Image.file(File(path), fit: BoxFit.cover)
                      : const Icon(Icons.broken_image),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sticker['caption'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
