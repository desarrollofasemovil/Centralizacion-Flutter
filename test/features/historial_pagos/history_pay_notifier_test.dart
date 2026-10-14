import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/api/services/api_providers.dart';
import 'package:tramiapp_flutter/core/api/services/payment_history_api_service.dart';
import 'package:tramiapp_flutter/core/models/document_type_dto.dart';
import 'package:tramiapp_flutter/core/models/payment_history_dto.dart';
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/core/models/validation_response_dto.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/features/historial_pagos/application/history_pay_notifier.dart';

UserDTO _user(int id) => UserDTO(
  id: id,
  address: 'Calle 1',
  documentType: DocumentTypeDTO(id: 1, name: 'CC'),
  documentTypeId: 1,
  email: 'u$id@correo.co',
  firstName: 'Usuario',
  lastName: '$id',
  loginStatus: true,
  nationalId: '$id',
  password: '',
  phoneNumber: '300',
  birthDate: '1990-01-01',
);

/// Sesión controlable desde el test.
class _Session extends SessionNotifier {
  _Session(this.initial);

  final UserDTO? initial;

  @override
  UserDTO? build() => initial;

  void switchTo(UserDTO? user) => state = user;
}

/// Registra cada lectura del historial (con qué usuario) y responde vacío con
/// el envelope 404 real de la API.
class _CountingHistoryApi implements PaymentHistoryApiService {
  final requestedUserIds = <int>[];

  @override
  Future<dynamic> getHistoryPaymentByUser(int id) async {
    requestedUserIds.add(id);
    return {
      'codeStatus': 404,
      'booleanStatus': false,
      'sentencesError': 'Notfound',
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

({ProviderContainer container, _CountingHistoryApi api}) _setUp({
  int? userId = 7,
}) {
  final api = _CountingHistoryApi();
  final container = ProviderContainer(
    overrides: [
      sessionProvider.overrideWith(
        () => _Session(userId == null ? null : _user(userId)),
      ),
      paymentHistoryApiServiceProvider.overrideWithValue(api),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, api: api);
}

/// Deja correr el `Future.microtask` del `build` y la lectura.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  refreshTests();

  test(
    'cada entrada al Historial vuelve a pedir la lista (autoDispose)',
    () async {
      final (:container, :api) = _setUp();

      // Primera visita al Historial.
      final first = container.listen(historyPayNotifierProvider, (_, _) {});
      await _settle();
      expect(api.requestedUserIds, [7]);

      // Se sale de la pantalla: nadie escucha, el provider se descarta.
      first.close();
      await container.pump();

      // Se vuelve a entrar (p. ej. Pagar → "Verificar estado" → Historial).
      container.listen(historyPayNotifierProvider, (_, _) {});
      await _settle();
      expect(api.requestedUserIds, [7, 7]);
      expect(container.read(historyPayNotifierProvider).value, isEmpty);
    },
  );

  test(
    'un cambio de usuario vuelve a pedir la lista con el nuevo id',
    () async {
      final (:container, :api) = _setUp();
      container.listen(historyPayNotifierProvider, (_, _) {});
      await _settle();
      expect(api.requestedUserIds, [7]);

      // Cerrar sesión y entrar con otra cuenta.
      (container.read(sessionProvider.notifier) as _Session).switchTo(
        _user(42),
      );
      container.read(historyPayNotifierProvider);
      await _settle();

      expect(api.requestedUserIds, [7, 42]);
    },
  );

  test('sin sesión no pide nada y la lista queda vacía', () async {
    final (:container, :api) = _setUp(userId: null);
    container.listen(historyPayNotifierProvider, (_, _) {});
    await _settle();

    expect(api.requestedUserIds, isEmpty);
    expect(container.read(historyPayNotifierProvider).value, isEmpty);
  });
}

/// Historial con pagos reales y sincronización controlable.
class _SyncingHistoryApi implements PaymentHistoryApiService {
  final reads = <int>[];
  final synced = <int>[];
  Completer<void>? syncGate;

  static Map<String, dynamic> _row(int id, String status) => {
    'id': id,
    'statusType': status,
    'idStatusType': switch (status) {
      'APROBADA' => 1,
      'COMENZADA' => 2,
      _ => 3,
    },
  };

  @override
  Future<dynamic> getHistoryPaymentByUser(int id) async {
    reads.add(id);
    return [
      _row(1, 'APROBADA'),
      _row(2, 'COMENZADA'),
      _row(3, 'COMENZADA'),
      _row(4, 'FALLIDA'),
    ];
  }

  @override
  Future<ValidationResponseDTO> syncPaymentStatus(int idHistory) async {
    synced.add(idHistory);
    if (syncGate != null) await syncGate!.future;
    return ValidationResponseDTO(codeStatus: 502, booleanStatus: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void refreshTests() {
  group('deslizar para refrescar', () {
    late ProviderContainer container;
    late _SyncingHistoryApi api;
    late List<AsyncValue<PaymentHistoryListDTO>> states;

    setUp(() async {
      api = _SyncingHistoryApi();
      container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(() => _Session(_user(7))),
          paymentHistoryApiServiceProvider.overrideWithValue(api),
        ],
      );
      states = [];
      container.listen(
        historyPayNotifierProvider,
        (_, next) => states.add(next),
      );
      await _settle();
      states.clear();
      api.reads.clear();
    });

    tearDown(() => container.dispose());

    test('sincroniza solo los COMENZADA y recarga la lista UNA vez', () async {
      await container
          .read(historyPayNotifierProvider.notifier)
          .refreshPending();

      expect(api.synced, [2, 3]);
      expect(api.reads, [7]);
    });

    test('la lista visible nunca pasa a loading (no parpadea)', () async {
      await container
          .read(historyPayNotifierProvider.notifier)
          .refreshPending();

      expect(states, isNotEmpty);
      expect(states.where((s) => s.isLoading), isEmpty);
      expect(container.read(historyPayNotifierProvider).value, hasLength(4));
    });

    test('mientras sincroniza, solo esas tarjetas están cargando', () async {
      api.syncGate = Completer<void>();
      final refresh = container
          .read(historyPayNotifierProvider.notifier)
          .refreshPending();
      await _settle();

      expect(container.read(historySyncingIdsProvider), {2, 3});

      api.syncGate!.complete();
      await refresh;
      expect(container.read(historySyncingIdsProvider), isEmpty);
    });
  });
}
