import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    firebaseError = error.toString();
  }
  runApp(UserAdminApp(firebaseError: firebaseError));
}

class UserAdminApp extends StatelessWidget {
  final String? firebaseError;

  const UserAdminApp({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context) {
    if (firebaseError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cấu hình Firebase',
        theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
        home: FirebaseSetupScreen(error: firebaseError!),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Admin Dashboard',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        ),
        home: const LoginScreen(),
      ),
    );
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
                  const Text('Chưa cấu hình Firebase', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Ứng dụng đã chạy nhưng chưa thể kết nối database. Hãy chạy các lệnh sau trong thư mục project:'),
                  const SizedBox(height: 16),
                  SelectableText('firebase login\ndart pub global activate flutterfire_cli\nflutterfire configure'),
                  const SizedBox(height: 16),
                  const Text('Trong flutterfire configure, chọn Firebase project và platform Web, sau đó chạy lại flutter run -d chrome.'),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Chi tiết lỗi'),
                    children: [Padding(padding: const EdgeInsets.all(12), child: SelectableText(error))],
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
