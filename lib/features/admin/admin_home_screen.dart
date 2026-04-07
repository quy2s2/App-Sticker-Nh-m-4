// lib/features/admin/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:stickit_app/features/admin/user_management_screen.dart';
import 'package:stickit_app/features/admin/album_management_screen.dart';
import 'package:stickit_app/features/admin/feedback_management_screen.dart';
import '../../services/session_manager.dart';
import '../auth/login_screen.dart';
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text(
    'StickIt - Admin',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  backgroundColor: Colors.redAccent,
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
),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AdminButton(
              icon: Icons.people,
              label: 'Quản lý người dùng',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserManagementScreen(), // xóa const
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _AdminButton(
              icon: Icons.image,
              label: 'Quản lý Album Sticker',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumManagementScreen(), // xóa const
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _AdminButton(
              icon: Icons.feedback,
              label: 'Quản lý phản hồi',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedbackManagementScreen(), // xóa const
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= ADMIN BUTTON WIDGET =================
class _AdminButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}
