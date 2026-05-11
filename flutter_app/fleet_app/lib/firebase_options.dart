import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyDM-P5zR2V5jmh7GRivF6pjQ-LGwC0W6dc',
    appId:             '1:743912195219:web:a685e9521e4c75627f7966',
    messagingSenderId: '743912195219',
    projectId:         'fleetsystem-9ac31',
    authDomain:        'fleetsystem-9ac31.firebaseapp.com',
    storageBucket:     'fleetsystem-9ac31.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyDM-P5zR2V5jmh7GRivF6pjQ-LGwC0W6dc',
    appId:             '1:743912195219:android:eedc5c9d77d1ee387f7966',
    messagingSenderId: '743912195219',
    projectId:         'fleetsystem-9ac31',
    storageBucket:     'fleetsystem-9ac31.firebasestorage.app',
  );
}
