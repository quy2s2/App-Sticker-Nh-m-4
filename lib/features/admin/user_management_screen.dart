import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final data = await AppDatabase.instance.getAllUsers();
    setState(() => users = data);
  }

  Future<void> changeRole(int id, String role) async {
    await AppDatabase.instance.updateUserRole(id, role);
    loadUsers();
  }

  Future<void> deleteUser(int id) async {
    await AppDatabase.instance.deleteUser(id);
    loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý User')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) {
          final u = users[i];
          return Card(
            child: ListTile(
              title: Text(u['username']),
              subtitle: Text('Role: ${u['role']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () {
                      final newRole =
                          u['role'] == 'admin' ? 'user' : 'admin';
                      changeRole(u['id'], newRole);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => deleteUser(u['id']),
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
