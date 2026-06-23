import 'bootstrap.dart';
import 'core/flavor/flavors.dart';
import 'firebase/firebase_options_municipios.dart';

/// Entrypoint del flavor `municipios` (Trami App Municipios).
/// Ejecutar: flutter run --flavor municipios -t lib/main_municipios.dart
Future<void> main() =>
    bootstrap(flavorMunicipios, DefaultFirebaseOptions.currentPlatform);
