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
    apiKey: 'AIzaSyBjkg_r5MWLV1Vv8IkMVBuNOI77QxJ7r5U',
    appId: '1:985195089189:android:453b04edb7d09d38ffdecc',
    messagingSenderId: '985195089189',
    projectId: 'alx-clima',
    storageBucket: 'alx-clima.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCdGQGFMahj59SJ6LxuAuZfa5GdmvlJdFA',
    appId: '1:985195089189:ios:1684133ccaf6e427ffdecc',
    messagingSenderId: '985195089189',
    projectId: 'alx-clima',
    storageBucket: 'alx-clima.firebasestorage.app',
    iosBundleId: 'com.tsty.mx.alxClima',
  );

}