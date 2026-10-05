import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'play_update_gateway.dart';

/// Actualización inmediata de Google Play (port de `checkForAppUpdate()` de
/// `MainActivity.kt`). Solo Android.
///
/// El `onResume()` del Kotlin (reanudar una actualización a medias al volver a
/// primer plano) **no se porta aquí**: el plugin `in_app_update` ya lo hace en
/// nativo (`onActivityResumed`) en cuanto se lanzó una actualización inmediata
/// en el proceso. Repetirlo desde Dart abría un segundo flujo de Play.
///
/// No sustituye al `force_update` de Remote Config: conviven sin tocarse.
class InAppUpdateService {
  InAppUpdateService(this._gateway, {required this.enabled});

  final PlayUpdateGateway _gateway;

  /// Solo Android (fuera de web): en el resto no hay Play Core.
  final bool enabled;

  /// Al arrancar: inicia si hay actualización y también reanuda una a medias.
  /// Esto último cubre el arranque en frío (el proceso murió durante la
  /// descarga), donde el plugin aún no sabe que había un flujo inmediato.
  Future<void> checkOnStart() async {
    if (!enabled) return;
    try {
      final state = await _gateway.check();
      if (state != PlayUpdateState.none) await _gateway.startImmediate();
    } catch (e) {
      // Fuera de Play (APK instalado a mano) falla con ERROR_APP_NOT_OWNED.
      debugPrint('InAppUpdateService error: $e');
    }
  }
}

final inAppUpdateServiceProvider = Provider<InAppUpdateService>(
  (ref) => InAppUpdateService(
    InAppUpdateGateway(),
    enabled: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
  ),
);
