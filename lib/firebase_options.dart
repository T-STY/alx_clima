import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no configurado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_API_KEY_AQUI',
    appId: 'TU_APP_ID_AQUI',
    messagingSenderId: 'TU_SENDER_ID_AQUI',
    projectId: 'TU_PROJECT_ID_AQUI',
    storageBucket: 'TU_STORAGE_BUCKET_AQUI',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU_API_KEY_AQUI',
    appId: 'TU_APP_ID_AQUI',
    messagingSenderId: 'TU_SENDER_ID_AQUI',
    projectId: 'TU_PROJECT_ID_AQUI',
    storageBucket: 'TU_STORAGE_BUCKET_AQUI',
    iosBundleId: 'com.example.alxClima',
  );
}
