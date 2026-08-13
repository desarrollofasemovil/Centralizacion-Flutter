import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Versión y número de build reales de la app, leídos del bundle nativo.
///
/// Se cachean una sola vez en el arranque (`AppInfo.init()` desde `bootstrap`)
/// porque `PackageInfo.fromPlatform()` es asíncrono y hay que consultarlo desde
/// sitios síncronos (Remote Config, correo de soporte).
class AppInfo {
  AppInfo._();

  /// Build al que caemos si la lectura nativa falla. Deliberadamente altísimo:
  /// `force_update` compara `currentBuildNumber < minimumBuildNumber`, así que un
  /// valor alto significa "no forzar". Si no sabemos en qué build estamos, lo
  /// seguro es NO sacar al usuario de la app.
  static const int fallbackBuildNumber = 999999;

  static const String fallbackVersion = '1.0.0';

  static String _version = fallbackVersion;
  static int _buildNumber = fallbackBuildNumber;

  /// Versión visible (`1.0.0`).
  static String get version => _version;

  /// Número de build (`+1` del pubspec), usado por `force_update`.
  static int get buildNumber => _buildNumber;

  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) _version = info.version;
      final parsed = int.tryParse(info.buildNumber);
      if (parsed != null) _buildNumber = parsed;
    } catch (e) {
      debugPrint('AppInfo.init error: $e — se usan los valores por defecto.');
    }
  }
}
