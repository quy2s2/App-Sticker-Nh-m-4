import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/database/app_database.dart';
import 'user_sticker_screen.dart';
import 'user_profile_screen.dart';
import 'reminder/my_reminder_screen.dart';
import 'feedback_screen.dart';
import '../../services/session_manager.dart';
import '../auth/login_screen.dart';
class UserHomeScreen extends StatefulWidget {
  final int? userId;

  const UserHomeScreen({super.key, this.userId});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String? selectedStickerPath;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? avatarPath;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => isLoading = true);

    int? id = widget.userId;

    // Nếu userId chưa có, lấy từ SharedPreferences
    if (id == null) {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('current_username');
      if (username != null) {
        // Lấy user theo username
        final users = await AppDatabase.instance.getAllUsers();
        final matched = users.firstWhere(
          (u) => u['username'] == username,
          orElse: () => {},
        );
        if (matched.isNotEmpty) id = matched['id'] as int;
      }
    }

    // Nếu vẫn null, dùng user mặc định id = 1
    id ??= 1;

    final data = await AppDatabase.instance.getUserById(id);

    setState(() {
      userData = data;
      avatarPath = data?['avatarPath'];
      isLoading = false;
    });
  }

  Future<void> _pickAvatar() async {
    if (userData == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          avatarPath = pickedFile.path;
        });

        await AppDatabase.instance.updateUserAvatar(userData!['id'], avatarPath!);

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
    final screenWidth = MediaQuery.of(context).size.width;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    File? avatarFile = avatarPath != null ? File(avatarPath!) : null;

    return Scaffold(
      appBar: AppBar(
  backgroundColor: Colors.indigo,
  elevation: 4,
  centerTitle: true,
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        await SessionManager.clearSession();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
    ),
  ],
  title: GestureDetector(
    onTap: () async {
      if (userData != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(userId: userData!['id']),
          ),
        );
        _loadUser();
      }
    },
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _pickAvatar,
          child: CircleAvatar(
            radius: 20,
            backgroundImage: avatarFile != null && avatarFile.existsSync()
                ? FileImage(avatarFile)
                : null,
            backgroundColor: Colors.indigo.shade200,
            child: avatarFile == null || !avatarFile.existsSync()
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          userData?['fullName'] ?? 'Người dùng',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.indigo.shade200, Colors.blue.shade200],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icons/sticker_hero.png',
                          width: screenWidth * 0.35,
                          height: screenWidth * 0.35,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.redAccent,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Chào mừng bạn đến với StickIt!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Chúng tôi rất vui được đồng hành cùng bạn.\n'
                        'Hãy bắt đầu tạo và sưu tầm sticker của riêng bạn!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildButton(
                        context,
                        icon: Icons.sticky_note_2,
                        label: 'Xem Sticker của bạn',
                        color: Colors.indigo,
                        onTap: () async {
                          final result = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserStickerScreen(),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              selectedStickerPath = result;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bạn đã chọn sticker!')),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildButton(
                        context,
                        icon: Icons.alarm,
                        label: 'Nhắc nhở của tôi',
                        color: Colors.blueAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyReminderScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildButton(
                        context,
                        icon: Icons.feedback,
                        label: 'Gửi phản hồi',
                        color: Colors.orangeAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FeedbackScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      if (selectedStickerPath != null &&
                          File(selectedStickerPath!).existsSync()) ...[
                        const Text(
                          'Sticker bạn đã chọn:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(selectedStickerPath!),
                            width: screenWidth * 0.3,
                            height: screenWidth * 0.3,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
