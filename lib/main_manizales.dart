import 'bootstrap.dart';
import 'core/flavor/flavors.dart';
import 'firebase/firebase_options_manizales.dart';

/// Entrypoint del flavor `manizales` (Trami App Manizales).
/// ⚠️ No desarrollar hasta terminar Centralización (ver CLAUDE.md regla 5).
/// Ejecutar: flutter run --flavor manizales -t lib/main_manizales.dart
Future<void> main() =>
    bootstrap(flavorManizales, DefaultFirebaseOptions.currentPlatform);
