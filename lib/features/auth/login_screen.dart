import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';
import '../role/role_guard.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    // 👉 login + lấy role
    final role = await AppDatabase.instance.loginAndGetRole(
      username,
      password,
    );

    if (role == null) {
      _showMessage('Sai tài khoản hoặc mật khẩu');
      return;
    }

    // 👉 Điều hướng qua RoleGuard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RoleGuard(role: role),
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StickIt - Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '📝 StickIt',
              style: TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _login,
              child: const Text('Đăng nhập'),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}
