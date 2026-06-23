import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado global de la app — puerto de `AppStatusManager.kt` (BACKEND §1.1).
///
/// Lo publica el [GlobalErrorInterceptor] ante errores de red y el lector de
/// Remote Config (`app_status_config`) ante mantenimiento/forzar actualización.
enum AppStatusType { operational, maintenance, forceUpdate, serverError }

class AppStatus {
  final AppStatusType type;
  final String title;
  final String message;

  /// `true` => bloqueo total (pantalla de error a página completa).
  final bool isBlocking;

  const AppStatus({
    this.type = AppStatusType.operational,
    this.title = '',
    this.message = '',
    this.isBlocking = false,
  });

  AppStatus copyWith({
    AppStatusType? type,
    String? title,
    String? message,
    bool? isBlocking,
  }) {
    return AppStatus(
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isBlocking: isBlocking ?? this.isBlocking,
    );
  }
}

class AppStatusNotifier extends Notifier<AppStatus> {
  @override
  AppStatus build() => const AppStatus();

  /// Aplica las MISMAS reglas de prioridad del Kotlin:
  /// - un `SERVER_ERROR` activo no se limpia con un `OPERATIONAL`;
  /// - un `FORCE_UPDATE` nunca lo tapa un `SERVER_ERROR`.
  void updateStatus(AppStatus newStatus) {
    final current = state;

    if (current.type == AppStatusType.serverError &&
        newStatus.type == AppStatusType.operational) {
      return;
    }
    if (current.type == AppStatusType.forceUpdate &&
        newStatus.type == AppStatusType.serverError) {
      return;
    }
    state = newStatus;
  }

  void clearStatus() {
    state = const AppStatus(type: AppStatusType.operational);
  }

  void setNonBlockingError() {
    if (state.type == AppStatusType.serverError) {
      state = state.copyWith(isBlocking: false);
    }
  }
}

/// Estado global de la app, observable por toda la UI.
final appStatusProvider =
    NotifierProvider<AppStatusNotifier, AppStatus>(AppStatusNotifier.new);
