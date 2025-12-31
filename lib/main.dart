import 'package:flutter/material.dart';
import 'features/auth/login_screen.dart';

void main() {
  runApp(const StickItApp());
}

class StickItApp extends StatelessWidget {
  const StickItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StickIt',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange,
      ),
      home: const LoginScreen(),
    );
  }
}
