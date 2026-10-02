// Opciones de Firebase para el flavor `municipios` (proyecto betaappcentralizate).
//
// Android construido a partir del `google-services.json` existente (cliente
// com.tramites1cero1.centralizacion). Web tomado de la config del SDK JS
// registrada en la consola de Firebase para el mismo proyecto. iOS se
// completa en la Fase 5 cuando se tenga el `GoogleService-Info.plist`. Cuando
// se regenere con FlutterFire CLI, este archivo será reemplazado por el
// generado.
//
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'iOS se configura en la Fase 5 (falta GoogleService-Info.plist).',
        );
      default:
        throw UnsupportedError(
          'FirebaseOptions no configuradas para $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD0hntdf8WSq_8I2S7e0bCRqQjCwpRV_vs',
    appId: '1:577349260806:android:0705c3ebc40d159bff1587',
    messagingSenderId: '577349260806',
    projectId: 'betaappcentralizate',
    storageBucket: 'betaappcentralizate.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqTVpl77BdpGzE4Kd5uXzr5Jd7teGPhJo',
    appId: '1:577349260806:web:f0dd07e205fc7fcfff1587',
    messagingSenderId: '577349260806',
    projectId: 'betaappcentralizate',
    authDomain: 'betaappcentralizate.firebaseapp.com',
    storageBucket: 'betaappcentralizate.firebasestorage.app',
    measurementId: 'G-JH2BNW2VQ4',
  );
}
