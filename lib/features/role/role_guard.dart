import 'package:flutter/material.dart';
import '../admin/admin_home_screen.dart';
import '../user/user_home_screen.dart';

class RoleGuard extends StatelessWidget {
  final String role;
  final int userId; // ✅ Thêm userId

  const RoleGuard({
    super.key,
    required this.role,
    required this.userId, // ✅ Bắt buộc
  });

  @override
  Widget build(BuildContext context) {
    if (role == 'admin') {
      return const AdminHomeScreen();
    }
    // ✅ Truyền userId xuống UserHomeScreen
    return UserHomeScreen(userId: userId);
  }
}
