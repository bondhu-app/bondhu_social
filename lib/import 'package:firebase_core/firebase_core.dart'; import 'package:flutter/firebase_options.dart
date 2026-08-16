import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web configuration is not available.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'This platform is not configured.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBiAdWhCS12QN8qhi4esIOjwqQ1zPzetwg',
    appId: '1:363053068335:android:2edc8d7df9b0c8d8fd16da',
    messagingSenderId: '363053068335',
    projectId: 'bondhu-social-c01e2',
    storageBucket: 'bondhu-social-c01e2.firebasestorage.app',
  );
}
