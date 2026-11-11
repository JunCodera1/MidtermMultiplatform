// Firebase configuration cho Web và Android (iOS/desktop chưa cấu hình: chạy `flutterfire configure`).
// This file contains public Firebase client identifiers, not private secrets.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
            'Chưa cấu hình Firebase cho nền tảng này. Chạy: flutterfire configure.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  // Lấy từ android/app/google-services.json (app com.example.user_admin_app).
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDSvqQ8CQcQGrdPHnRhwJ-OHD7F3e3sA6k',
    appId: '1:42995230382:android:11534fadc7de26ac37ef3f',
    messagingSenderId: '42995230382',
    projectId: 'mychat-5eebb',
    storageBucket: 'mychat-5eebb.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCon_jeeLMQNzcZdR29FM0VBuCLpRLdQAg',
    appId: '1:42995230382:web:31b61e0041261a8e37ef3f',
    messagingSenderId: '42995230382',
    projectId: 'mychat-5eebb',
    authDomain: 'mychat-5eebb.firebaseapp.com',
    storageBucket: 'mychat-5eebb.firebasestorage.app',
    measurementId: 'G-XFJZW3416K',
    databaseURL: 'https://mychat-5eebb-default-rtdb.firebaseio.com',
  );
}
