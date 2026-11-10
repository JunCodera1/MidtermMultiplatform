// Generated Firebase configuration for the User Admin Web app.
// This file contains public Firebase client identifiers, not private secrets.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError('Android Firebase options are not configured for this Web setup.');
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError('Firebase options are configured for Web only.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

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
