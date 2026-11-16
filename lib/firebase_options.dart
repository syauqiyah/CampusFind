// File generated manually for CampusFind UNESA (Web & Android)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDC7V3LrgpekkGyUscri2UY2F75P9qPzP0',
    appId: '1:669075448582:web:98e6cb307e683381c2f487',
    messagingSenderId: '669075448582',
    projectId: 'campusfind-unesa',
    authDomain: 'campusfind-unesa.firebaseapp.com',
    storageBucket: 'campusfind-unesa.firebasestorage.app',
    measurementId: 'G-12XM0XC3L2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCIVLxzBIGjlzllS4lKXFWVsjyl2wMgAdE',
    appId: '1:669075448582:android:9ab7ca08e984c3efc2f487',
    messagingSenderId: '669075448582',
    projectId: 'campusfind-unesa',
    storageBucket: 'campusfind-unesa.firebasestorage.app',
  );
}