import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';
import 'package:tramiapp_flutter/core/api/services/api_providers.dart';
import 'package:tramiapp_flutter/core/api/services/payment_history_api_service.dart';
import 'package:tramiapp_flutter/core/models/document_type_dto.dart';
import 'package:tramiapp_flutter/core/models/payment_history_dto.dart';
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/core/models/validation_response_dto.dart';
import 'package:tramiapp_flutter/core/review/review_prompt_service.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/features/historial_pagos/application/history_pay_notifier.dart';
import 'package:tramiapp_flutter/features/pagos/application/payment_processing_notifier.dart';

import '../../support/recording_analytics.dart';
import '../../support/spy_review_prompt_service.dart';

const _approved = 1;
const _started = 2;
const _failed = 3;

PaymentHistoryDTO _payment(int id, int status) => PaymentHistoryDTO(
  id: id,
  userFirtName: 'Ana',
  amount: 25000,
  paymentDate: '2026-10-19',
  status: status == _approved,
  idStatusType: status,
  alcaldia: 'Alcaldía',
  procedureName: 'Predial',
  statusType: const {1: 'APROBADA', 2: 'COMENZADA', 3: 'FALLIDA'}[status] ?? '',
  idimpuesto: '12',
  factura: 'F-1',
  codigoEntidad: '05030',
);

/// Backend falso: `syncPaymentStatus` aplica el estado que tendrá el pago.
class _FakeHistoryApi implements PaymentHistoryApiService {
  _FakeHistoryApi(this.items);

  List<PaymentHistoryDTO> items;
  final Map<int, int> statusAfterSync = {};
  bool failSync = false;

  @override
  Future<PaymentHistoryListDTO> getHistoryPaymentByUser(int id) async =>
      List.of(items);

  @override
  Future<ValidationResponseDTO> syncPaymentStatus(int idHistory) async {
    if (failSync) throw StateError('sync falló');
    final next = statusAfterSync[idHistory];
    if (next != null) {
      items = [
        for (final p in items) p.id == idHistory ? _payment(p.id, next) : p,
      ];
    }
    return ValidationResponseDTO();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LoggedIn extends SessionNotifier {
  @override
  UserDTO? build() => UserDTO(
    id: 9,
    address: 'Calle 1',
    documentType: DocumentTypeDTO(id: 1, name: 'CC'),
    documentTypeId: 1,
    email: 'ana@correo.co',
    firstName: 'Ana',
    lastName: 'Pérez',
    loginStatus: true,
    nationalId: '123',
    password: '',
    phoneNumber: '300',
    birthDate: '1990-01-01',
  );
}

({ProviderContainer container, RecordingAnalytics analytics}) _container(
  _FakeHistoryApi api,
) {
  final analytics = RecordingAnalytics();
  final container = ProviderContainer(
    overrides: [
      sessionProvider.overrideWith(_LoggedIn.new),
      paymentHistoryApiServiceProvider.overrideWithValue(api),
      reviewPromptServiceProvider.overrideWithValue(SpyReviewPromptService()),
      analyticsServiceProvider.overrideWithValue(analytics),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, analytics: analytics);
}

void main() {
  group('«Verificar estado» (procesamiento)', () {
    Future<RecordingAnalytics> verify(
      WidgetTester tester,
      _FakeHistoryApi api,
    ) async {
      final (:container, :analytics) = _container(api);
      container.listen(paymentProcessingNotifierProvider, (_, _) {});
      await tester.pump(const Duration(seconds: 31)); // cuenta regresiva
      await container
          .read(paymentProcessingNotifierProvider.notifier)
          .onCheckStatusClick(municipalityId: 3, origin: PaymentOrigin.psv);
      await tester.pump();
      return analytics;
    }

    testWidgets('pasa a aprobado: pago_verificado + purchase', (tester) async {
      final api = _FakeHistoryApi([
        _payment(4, _approved),
        _payment(7, _started),
      ])..statusAfterSync[7] = _approved;

      final analytics = await verify(tester, api);

      expect(analytics.names, ['pago_verificado', 'purchase']);
      expect(analytics.single('pago_verificado'), {
        'municipio_id': 3,
        'origen': 'psv',
        'resultado': 'aprobado',
        'estado_id': _approved,
        'pantalla': 'procesamiento',
        'valor': 25000.0,
      });
      expect(analytics.single('purchase')!['transaction_id'], 'hist_7');
      expect(analytics.single('purchase')!['value'], 25000.0);
    });

    testWidgets('sigue pendiente: sin purchase', (tester) async {
      final api = _FakeHistoryApi([_payment(7, _started)]);

      final analytics = await verify(tester, api);

      expect(analytics.names, ['pago_verificado']);
      expect(analytics.single('pago_verificado')!['resultado'], 'pendiente');
    });

    testWidgets('fallido: rechazado, sin purchase', (tester) async {
      final api = _FakeHistoryApi([_payment(7, _started)])
        ..statusAfterSync[7] = _failed;

      final analytics = await verify(tester, api);

      expect(analytics.names, ['pago_verificado']);
      expect(analytics.single('pago_verificado')!['resultado'], 'rechazado');
    });

    testWidgets('ya estaba aprobado: no se cuenta otra compra', (tester) async {
      final api = _FakeHistoryApi([_payment(7, _approved)]);

      final analytics = await verify(tester, api);

      expect(analytics.names, ['pago_verificado']);
    });

    testWidgets('historial vacío: pago_error', (tester) async {
      final analytics = await verify(tester, _FakeHistoryApi([]));

      expect(analytics.single('pago_error'), {
        'municipio_id': 3,
        'origen': 'psv',
        'etapa': 'verificacion',
        'motivo': 'historial_vacio',
      });
    });

    testWidgets('la sincronización falla: pago_error con motivo', (
      tester,
    ) async {
      final api = _FakeHistoryApi([_payment(7, _started)])..failSync = true;

      final analytics = await verify(tester, api);

      expect(analytics.names, ['pago_error']);
      expect(analytics.single('pago_error')!['motivo'], 'StateError');
    });
  });

  group('Refrescar el historial', () {
    test('un pendiente que pasa a aprobado manda purchase', () async {
      final api = _FakeHistoryApi([
        _payment(7, _started),
        _payment(8, _started),
      ])..statusAfterSync[7] = _approved;
      final (:container, :analytics) = _container(api);
      container.listen(historyPayNotifierProvider, (_, _) {});
      final notifier = container.read(historyPayNotifierProvider.notifier);
      await notifier.fetchHistory();

      await notifier.refreshPending(municipalityId: 3);

      expect(analytics.names, [
        'pago_verificado',
        'purchase',
        'pago_verificado',
      ]);
      expect(analytics.events.first.$2!['pantalla'], 'historial');
      expect(analytics.single('purchase')!['transaction_id'], 'hist_7');
    });

    test('sin municipio (llamadas internas) no mide', () async {
      final api = _FakeHistoryApi([_payment(7, _started)])
        ..statusAfterSync[7] = _approved;
      final (:container, :analytics) = _container(api);
      container.listen(historyPayNotifierProvider, (_, _) {});
      final notifier = container.read(historyPayNotifierProvider.notifier);
      await notifier.fetchHistory();

      await notifier.syncPayment(7);

      expect(analytics.events, isEmpty);
    });
  });
}
