// Placeholder de opciones de Firebase para el flavor `manizales`.
//
// Manizales usará su PROPIO proyecto Firebase (analytics/push/crashlytics
// separados). Aún no existe. Generar con FlutterFire CLI cuando se cree el
// proyecto (ver FLAVORS.md §7) y reemplazar este archivo:
//
//   flutterfire configure --project=trami-manizales \
//     --out=lib/firebase/firebase_options_manizales.dart \
//     --android-package-name=com.tramitesapp.manizales \
//     --ios-bundle-id=com.tramitesapp.manizales
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnimplementedError(
        'Firebase para el flavor manizales aún no está configurado. '
        'Crear el proyecto Firebase de Manizales y generar este archivo con '
        'FlutterFire CLI (ver FLAVORS.md §7).',
      );
}
