import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/app_database.dart';
import '../role/role_guard.dart';
import 'register_screen.dart';
import '../../services/session_manager.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
  final username = _usernameController.text.trim();
  final password = _passwordController.text.trim();

  if (username.isEmpty || password.isEmpty) {
    _showMessage('Vui lòng nhập đầy đủ thông tin', isError: true);
    return;
  }

  setState(() => _isLoading = true);

  try {
    // gọi DB
    final user = await AppDatabase.instance.loginAndGetUser(username, password);

    if (user != null) {
      // ✅ lưu session
      await SessionManager.saveSession(
        user['userId'],
        user['role'],
      );

      // lưu username
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_username', username);

      // điều hướng
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleGuard(
            role: user['role'] as String,
            userId: user['userId'] as int,
          ),
        ),
      );
    } else {
      _showMessage('Sai tài khoản hoặc mật khẩu', isError: true);
    }
  } catch (e) {
    _showMessage('Đăng nhập thất bại: $e', isError: true);
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
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
            const Text('📝 StickIt', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Đăng nhập'),
                  ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
