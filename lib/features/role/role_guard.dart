import 'package:flutter/material.dart';
import '../admin/admin_home_screen.dart';
import '../user/user_home_screen.dart';

class RoleGuard extends StatelessWidget {
  final String role;

  const RoleGuard({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    if (role == 'admin') {
      return const AdminHomeScreen();
    }
    return const UserHomeScreen();
  }
}
