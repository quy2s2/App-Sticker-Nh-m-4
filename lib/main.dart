import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'features/auth/login_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  // BẮT BUỘC khi dùng notification / async
  WidgetsFlutterBinding.ensureInitialized();

  // Kiểm tra platform - chỉ hỗ trợ mobile
  if (kIsWeb) {
    runApp(const WebNotSupportedApp());
    return;
  }

  // KHỞI TẠO NOTIFICATION
  await NotificationService.instance.init();

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

class WebNotSupportedApp extends StatelessWidget {
  const WebNotSupportedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StickIt',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phone_android,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'StickIt App',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ứng dụng này chỉ hỗ trợ trên thiết bị di động (Android/iOS)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng sử dụng ứng dụng trên điện thoại hoặc emulator Android/iOS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
