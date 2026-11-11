import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'screens/login_screen.dart';
import 'screens/product_list_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lớp bảo vệ toàn cục: lỗi khi dựng một widget chỉ thay widget đó bằng thông báo
  // gọn (không còn màn hình đỏ toàn trang); lỗi bất đồng bộ chưa được bắt chỉ ghi log.
  ErrorWidget.builder =
      (details) => _FriendlyError(message: details.exceptionAsString());
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('Lỗi chưa xử lý: $error\n$stack');
    return true;
  };

  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    firebaseError = error.toString();
  }
  runApp(ProductAdminApp(firebaseError: firebaseError));
}

class ProductAdminApp extends StatelessWidget {
  final String? firebaseError;

  const ProductAdminApp({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context) {
    if (firebaseError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cấu hình Firebase',
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
        home: FirebaseSetupScreen(error: firebaseError!),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Quản lý sản phẩm',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
    );
  }
}

/// Thay cho màn hình đỏ mặc định khi một widget bị lỗi khi dựng.
class _FriendlyError extends StatelessWidget {
  final String message;
  const _FriendlyError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Có lỗi hiển thị, hãy thử lại.\n$message',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quyết định màn hình đầu: đã đăng nhập thì vào thẳng danh sách, chưa thì vào đăng nhập.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const ProductListScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  final String error;

  const FirebaseSetupScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cloud_off, size: 52, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('Chưa cấu hình Firebase',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                      'Ứng dụng đã chạy nhưng chưa thể kết nối database. Hãy chạy các lệnh sau trong thư mục project:'),
                  const SizedBox(height: 16),
                  const SelectableText(
                      'firebase login\ndart pub global activate flutterfire_cli\nflutterfire configure'),
                  const SizedBox(height: 16),
                  const Text(
                      'Trong flutterfire configure, chọn Firebase project và platform Web, sau đó chạy lại flutter run -d chrome.'),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Chi tiết lỗi'),
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(error))
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
