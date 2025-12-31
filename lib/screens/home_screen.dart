import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StickIt Home')),
      body: const Center(
        child: Text(
          '🎉 Đăng nhập thành công!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
