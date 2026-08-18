// File generated for Firebase configuration.
// বন্ধু সোশ্যাল - Android Firebase Configuration

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'বন্ধু সোশ্যালের Web Firebase configuration এখনো সেটআপ করা হয়নি.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS Firebase configuration এখনো সেটআপ করা হয়নি.',
        );

      case TargetPlatform.macOS:
        throw UnsupportedError(
          'macOS Firebase configuration এখনো সেটআপ করা হয়নি.',
        );

      case TargetPlatform.windows:
        throw UnsupportedError(
          'Windows Firebase configuration এখনো সেটআপ করা হয়নি.',
        );

      case TargetPlatform.linux:
        throw UnsupportedError(
          'Linux Firebase configuration এখনো সেটআপ করা হয়নি.',
        );

      default:
        throw UnsupportedError(
          'এই platform-এর জন্য Firebase configuration নেই.',
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
