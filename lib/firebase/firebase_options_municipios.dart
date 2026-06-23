// Opciones de Firebase para el flavor `municipios` (proyecto betaappcentralizate).
//
// Construido a partir del `google-services.json` existente (cliente
// com.tramites1cero1.centralizacion). iOS se completa en la Fase 5 cuando se
// tenga el `GoogleService-Info.plist`. Cuando se regenere con FlutterFire CLI,
// este archivo será reemplazado por el generado.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase web aún no está configurado para el flavor municipios.',
      );
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
}
