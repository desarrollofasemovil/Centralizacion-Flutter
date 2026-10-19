import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/push_notifications_service.dart';
import 'analytics_service.dart';

/// Lo que pasa cada vez que el usuario entra a la Home de un municipio:
/// propiedad de usuario + `seleccion_municipio` en Analytics y suscripción al
/// tópico FCM del municipio para las notificaciones segmentadas.
///
/// Junta lo que en el original hacían `MainViewModel.trackMunicipalityEvent`
/// (desde `MainScreen`) y `MunicipalityViewModel.manageFirebaseSubscription`.
/// Se registra una sola vez por municipio y proceso, aunque la Home se
/// reconstruya.
class MunicipalityTracker {
  MunicipalityTracker(this._ref);

  final Ref _ref;
  int? _lastTrackedId;

  void onMunicipalityShown({required int id, required String name}) {
    if (name.trim().isEmpty || id == _lastTrackedId) return;
    _lastTrackedId = id;

    unawaited(
      _ref.read(analyticsServiceProvider).setMunicipality(id: id, name: name),
    );
    try {
      unawaited(
        _ref.read(pushNotificationsServiceProvider).subscribeToMunicipality(name),
      );
    } catch (_) {
      // Sin Firebase inicializado (pruebas): no hay a qué suscribirse.
    }
  }
}

final municipalityTrackerProvider = Provider<MunicipalityTracker>(
  MunicipalityTracker.new,
);
