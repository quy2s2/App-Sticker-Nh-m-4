// lib/features/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:stickit_app/data/database/app_database.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // ================= LOAD USERS =================
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await AppDatabase.instance.getAllUsers();
      if (!mounted) return;
      setState(() {
        users = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải người dùng: $e')));
    }
  }

  // ================= CHANGE ROLE =================
  Future<void> _changeRole(int id, String role) async {
    try {
      await AppDatabase.instance.updateUserRole(id, role);
      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đổi role thất bại: $e')));
    }
  }

  // ================= DELETE USER =================
  Future<void> _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: const Text('Bạn có chắc chắn muốn xóa người dùng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AppDatabase.instance.deleteUser(id);
      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa người dùng thất bại: $e')));
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý User'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text('Chưa có người dùng nào'))
              : ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final user = users[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(user['username'] ?? ''),
                        subtitle: Text('Role: ${user['role'] ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.swap_horiz),
                              tooltip: 'Đổi vai trò',
                              onPressed: () {
                                final newRole =
                                    user['role'] == 'admin' ? 'user' : 'admin';
                                _changeRole(user['id'], newRole);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Xóa người dùng',
                              color: Colors.red,
                              onPressed: () => _deleteUser(user['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
