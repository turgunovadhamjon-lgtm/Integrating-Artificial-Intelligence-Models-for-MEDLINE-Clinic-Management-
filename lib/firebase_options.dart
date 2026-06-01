// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      case TargetPlatform.windows: return windows;
      default: throw UnsupportedError('Not supported');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAnRU07amSOosDUY0V0tMul6R5PmER9F2c',
    appId: '1:399904131201:web:7e0a63b3d8e0123faca580',
    messagingSenderId: '399904131201',
    projectId: 'medline-93ddc',
    authDomain: 'medline-93ddc.firebaseapp.com',
    storageBucket: 'medline-93ddc.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwCmH4wlEigRqAjTll1BK8TkC8ZnhtgY0',
    appId: '1:399904131201:android:308fc0137ac2821aaca580',
    messagingSenderId: '399904131201',
    projectId: 'medline-93ddc',
    storageBucket: 'medline-93ddc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAYqV26o_dSv2qMxg1TOjT-YvdCwh4KmcM',
    appId: '1:399904131201:ios:0cd1ffd3392d5933aca580',
    messagingSenderId: '399904131201',
    projectId: 'medline-93ddc',
    storageBucket: 'medline-93ddc.firebasestorage.app',
    iosBundleId: 'com.example.medline',
  );

  // WINDOWS — YANGI APP YARATILGAN BO‘LSA
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAnRU07amSOosDUY0V0tMul6R5PmER9F2c',
    appId: '1:399904131201:windows:abcd1234efgh5678', // ← BU YERGA YANGI WINDOWS APP ID
    messagingSenderId: '399904131201',
    projectId: 'medline-93ddc',
    authDomain: 'medline-93ddc.firebaseapp.com',
    storageBucket: 'medline-93ddc.firebasestorage.app',
  );
}