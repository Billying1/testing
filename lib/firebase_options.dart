
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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD0IL6JNu3uA9TtF7t8D5WsMIoviieZdB8',
    appId: '1:193257205730:web:cbd45e0a2ec19bd81313bb',
    messagingSenderId: '193257205730',
    projectId: 'mobilenc-197ea',
    authDomain: 'mobilenc-197ea.firebaseapp.com',
    storageBucket: 'mobilenc-197ea.firebasestorage.app',
    measurementId: 'G-CN3RJS1WXZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC7IVqAKPigdsntbltHjatse5UT9qm-yuo',
    appId: '1:193257205730:android:9e52bbfa5281c6661313bb',
    messagingSenderId: '193257205730',
    projectId: 'mobilenc-197ea',
    storageBucket: 'mobilenc-197ea.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBgX0Dkju8HO4kWpzLgS4lihANaZ6lItCQ',
    appId: '1:193257205730:ios:5ea1101633eb22ce1313bb',
    messagingSenderId: '193257205730',
    projectId: 'mobilenc-197ea',
    storageBucket: 'mobilenc-197ea.firebasestorage.app',
    iosBundleId: 'com.example.tuan5',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBgX0Dkju8HO4kWpzLgS4lihANaZ6lItCQ',
    appId: '1:193257205730:ios:5ea1101633eb22ce1313bb',
    messagingSenderId: '193257205730',
    projectId: 'mobilenc-197ea',
    storageBucket: 'mobilenc-197ea.firebasestorage.app',
    iosBundleId: 'com.example.tuan5',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD0IL6JNu3uA9TtF7t8D5WsMIoviieZdB8',
    appId: '1:193257205730:web:050a9db16b5dfb1f1313bb',
    messagingSenderId: '193257205730',
    projectId: 'mobilenc-197ea',
    authDomain: 'mobilenc-197ea.firebaseapp.com',
    storageBucket: 'mobilenc-197ea.firebasestorage.app',
    measurementId: 'G-V72SECE987',
  );
}
