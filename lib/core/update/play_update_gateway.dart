import 'package:in_app_update/in_app_update.dart';

/// Lo único que le importa al servicio de la consulta a Play.
enum PlayUpdateState { none, available, inProgress }

abstract class PlayUpdateGateway {
  Future<PlayUpdateState> check();

  /// Abre (o reanuda) la pantalla de actualización inmediata de Play.
  Future<void> startImmediate();
}

/// Envuelve `in_app_update` (Play Core). Fuera de Play (APK instalado a mano)
/// `checkForUpdate` lanza: lo maneja el servicio.
class InAppUpdateGateway implements PlayUpdateGateway {
  @override
  Future<PlayUpdateState> check() async {
    final info = await InAppUpdate.checkForUpdate();
    return switch (info.updateAvailability) {
      // Kotlin: UPDATE_AVAILABLE && isUpdateTypeAllowed(IMMEDIATE).
      UpdateAvailability.updateAvailable when info.immediateUpdateAllowed =>
        PlayUpdateState.available,
      UpdateAvailability.developerTriggeredUpdateInProgress =>
        PlayUpdateState.inProgress,
      _ => PlayUpdateState.none,
    };
  }

  @override
  Future<void> startImmediate() => InAppUpdate.performImmediateUpdate();
}
