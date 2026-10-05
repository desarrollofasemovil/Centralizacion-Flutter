import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'play_update_gateway.dart';

/// Actualización inmediata de Google Play (port de `checkForAppUpdate()` y
/// `onResume()` de `MainActivity.kt`). Solo Android.
///
/// No sustituye al `force_update` de Remote Config: conviven sin tocarse.
class InAppUpdateService {
  InAppUpdateService(this._gateway, {required bool enabled})
      : _enabled = enabled;

  final PlayUpdateGateway _gateway;
  final bool _enabled;
  bool _busy = false;

  /// Al arrancar: inicia si hay actualización y también reanuda una a medias
  /// (en Android nativo lo hacía el `onResume` que sigue a `onCreate`; en
  /// Flutter no hay ese `resumed` inicial).
  Future<void> checkOnStart() => _run(
        (state) =>
            state == PlayUpdateState.available ||
            state == PlayUpdateState.inProgress,
      );

  /// Al volver a primer plano: solo reanuda. Con `available` no reabre, para
  /// no entrar en bucle si el usuario canceló.
  Future<void> onResume() =>
      _run((state) => state == PlayUpdateState.inProgress);

  Future<void> _run(bool Function(PlayUpdateState) shouldStart) async {
    // Al cerrarse la UI de Play la app recibe `resumed` con el flujo aún
    // activo: `_busy` evita abrir un segundo flujo.
    if (!_enabled || _busy) return;
    _busy = true;
    try {
      final state = await _gateway.check();
      if (shouldStart(state)) await _gateway.startImmediate();
    } catch (e) {
      debugPrint('InAppUpdateService error: $e');
    } finally {
      _busy = false;
    }
  }
}

final inAppUpdateServiceProvider = Provider<InAppUpdateService>(
  (ref) => InAppUpdateService(
    InAppUpdateGateway(),
    enabled: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
  ),
);
