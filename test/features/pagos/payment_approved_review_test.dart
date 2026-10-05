import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

import '../../support/spy_review_prompt_service.dart';

const _approved = 1;
const _pending = 3;

PaymentHistoryDTO _payment(int id, int status) => PaymentHistoryDTO(
      id: id,
      userFirtName: 'Ana',
      amount: 1000,
      paymentDate: '2026-10-05',
      status: status == _approved,
      idStatusType: status,
      alcaldia: 'Alcaldía',
      procedureName: 'Predial',
      statusType: '',
      idimpuesto: '1',
      factura: 'F-1',
      codigoEntidad: '001',
    );

/// Backend falso: `syncPaymentStatus` aplica el estado que tendrá el pago
/// tras la sincronización.
class _FakeHistoryApi implements PaymentHistoryApiService {
  _FakeHistoryApi(this.items);

  List<PaymentHistoryDTO> items;
  final Map<int, int> statusAfterSync = {};

  @override
  Future<PaymentHistoryListDTO> getHistoryPaymentByUser(int id) async =>
      List.of(items);

  @override
  Future<ValidationResponseDTO> syncPaymentStatus(int idHistory) async {
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

({ProviderContainer container, SpyReviewPromptService spy}) _container(
  _FakeHistoryApi api,
) {
  final spy = SpyReviewPromptService();
  final container = ProviderContainer(
    overrides: [
      sessionProvider.overrideWith(_LoggedIn.new),
      paymentHistoryApiServiceProvider.overrideWithValue(api),
      reviewPromptServiceProvider.overrideWithValue(spy),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, spy: spy);
}

void main() {
  group('Verificar estado tras pagar', () {
    Future<SpyReviewPromptService> verify(
      WidgetTester tester,
      _FakeHistoryApi api,
    ) async {
      final (:container, :spy) = _container(api);
      container.listen(paymentProcessingNotifierProvider, (_, _) {});
      await tester.pump(const Duration(seconds: 31)); // cuenta regresiva
      final navigate = await container
          .read(paymentProcessingNotifierProvider.notifier)
          .onCheckStatusClick();
      expect(navigate, isTrue);
      return spy;
    }

    testWidgets('el último pago queda aprobado: se pide la reseña',
        (tester) async {
      final api = _FakeHistoryApi([_payment(4, _approved), _payment(7, _pending)])
        ..statusAfterSync[7] = _approved;

      final spy = await verify(tester, api);

      expect(spy.moments, [ReviewTrigger.paymentApproved]);
    });

    testWidgets('el último ya estaba aprobado antes de verificar: no se pide',
        (tester) async {
      final api = _FakeHistoryApi([_payment(4, _pending), _payment(7, _approved)]);

      final spy = await verify(tester, api);

      expect(spy.moments, isEmpty);
    });

    testWidgets('el último pago sigue pendiente: no se pide', (tester) async {
      final api = _FakeHistoryApi([_payment(4, _approved), _payment(7, _pending)]);

      final spy = await verify(tester, api);

      expect(spy.moments, isEmpty);
    });
  });

  group('Sincronizar un pago desde el historial', () {
    Future<SpyReviewPromptService> sync(_FakeHistoryApi api, int id) async {
      final (:container, :spy) = _container(api);
      container.listen(historyPayNotifierProvider, (_, _) {});
      final notifier = container.read(historyPayNotifierProvider.notifier);
      await notifier.fetchHistory();
      await notifier.syncPayment(id);
      return spy;
    }

    test('pasa de pendiente a aprobado: se pide la reseña', () async {
      final api = _FakeHistoryApi([_payment(7, _pending)])
        ..statusAfterSync[7] = _approved;

      final spy = await sync(api, 7);

      expect(spy.moments, [ReviewTrigger.paymentApproved]);
    });

    test('ya estaba aprobado: sincronizarlo de nuevo no la pide', () async {
      final api = _FakeHistoryApi([_payment(7, _approved)]);

      final spy = await sync(api, 7);

      expect(spy.moments, isEmpty);
    });

    test('sigue pendiente: no la pide', () async {
      final api = _FakeHistoryApi([_payment(7, _pending)]);

      final spy = await sync(api, 7);

      expect(spy.moments, isEmpty);
    });
  });
}
