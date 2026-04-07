import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/database/app_database.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? userData;
  String? avatarPath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // ===== LẤY THÔNG TIN USER =====
  Future<void> _loadUser() async {
    setState(() => isLoading = true);

    final data = await AppDatabase.instance.getUserById(widget.userId);

    if (data == null) {
      // Nếu chưa có dữ liệu user trong DB, tạo user test
      await AppDatabase.instance.insertUser({
        'id': widget.userId,
        'fullName': 'Người dùng StickIt',
        'email': '',
        'phone': '',
        'dob': '',
        'avatarPath': null,
      });
    }

    final updatedData = await AppDatabase.instance.getUserById(widget.userId);

    setState(() {
      userData = updatedData;
      avatarPath = updatedData?['avatarPath'];
      isLoading = false;
    });
  }

  // ===== CHỌN ẢNH ĐẠI DIỆN =====
  Future<void> _pickAvatar() async {
    if (userData == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          avatarPath = pickedFile.path;
        });

        // Cập nhật avatar vào database
        await AppDatabase.instance.updateUserAvatar(widget.userId, avatarPath!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật ảnh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return const Scaffold(
        body: Center(child: Text('Không có dữ liệu người dùng')),
      );
    }

    File? avatarFile = avatarPath != null ? File(avatarPath!) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ===== AVATAR =====
            GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.indigo.shade200,
                backgroundImage: avatarFile != null && avatarFile.existsSync()
                    ? FileImage(avatarFile)
                    : null,
                child: avatarFile == null || !avatarFile.existsSync()
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // ===== TÊN =====
            Text(
              userData!['fullName'] ?? 'Người dùng',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ===== THÔNG TIN KHÁC =====
            _infoRow(Icons.email, 'Email', userData!['email']),
            const SizedBox(height: 8),
            _infoRow(Icons.phone, 'Số điện thoại', userData!['phone']),
            const SizedBox(height: 8),
            _infoRow(Icons.cake, 'Ngày sinh', userData!['dob']),
            const SizedBox(height: 24),

            // ===== NÚT CẬP NHẬT AVATAR =====
            ElevatedButton.icon(
              onPressed: _pickAvatar,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Cập nhật ảnh đại diện'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== WIDGET HIỂN THÔNG TIN =====
  Widget _infoRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value != null && value.isNotEmpty ? value : 'Chưa cập nhật',
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
