// Entrypoint por defecto (para `flutter run` sin `-t`). Redirige al flavor
// `municipios`. En CI/builds usa siempre el entrypoint explícito por flavor:
//   flutter run --flavor municipios -t lib/main_municipios.dart
//   flutter run --flavor manizales  -t lib/main_manizales.dart
import 'main_municipios.dart' as municipios;

Future<void> main() => municipios.main();
