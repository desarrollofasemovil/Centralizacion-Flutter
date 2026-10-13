import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/models/payment_history_dto.dart';

Map<String, dynamic> _row({int id = 10, String statusType = 'COMENZADA'}) => {
  'id': id,
  'userFirtName': 'Juan',
  'amount': 25000,
  'paymentDate': '2026-10-13',
  'status': false,
  'procedureName': 'Impuesto predial',
  'alcaldia': 'Amagá',
  'statusType': statusType,
  'idStatusType': 2,
  'idimpuesto': '1',
  'factura': 'FAC-001',
  'codigoEntidad': '05030',
};

/// Respuestas reales de `GET api/PaymentHistory/User/{id}`
/// (API `docs/api/payment-history.md`).
void main() {
  group('paymentHistoryFromResponse', () {
    test('lista directa: se parsea', () {
      final list = paymentHistoryFromResponse([_row(), _row(id: 11)]);

      expect(list.map((p) => p.id), [10, 11]);
      expect(list.first.isInProgress, isTrue);
      expect(list.first.amount, 25000);
    });

    test('sin pagos: el envelope 404 es una lista vacía, no un error', () {
      final list = paymentHistoryFromResponse({
        'codeStatus': 404,
        'booleanStatus': false,
        'sentencesError': 'Notfound',
        'result': null,
      });

      expect(list, isEmpty);
    });

    test('otro envelope (400 por id inválido) sí es un error', () {
      expect(
        () => paymentHistoryFromResponse({
          'codeStatus': 400,
          'booleanStatus': false,
          'sentencesError': 'el id no debe ser null y debe se mayor a cero',
        }),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('el id no debe ser null'),
          ),
        ),
      );
    });

    test('un registro con nulos no tumba el resto de la lista', () {
      final withNulls = {
        'id': 12,
        'userFirtName': null,
        'amount': null,
        'paymentDate': null,
        'status': null,
        'procedureName': null,
        'alcaldia': null,
        'statusType': null,
        'idStatusType': null,
        'idimpuesto': null,
        'factura': null,
        'codigoEntidad': null,
      };

      final list = paymentHistoryFromResponse([_row(), withNulls]);

      expect(list, hasLength(2));
      expect(list.last.statusType, '');
      expect(list.last.status, isFalse);
      expect(list.last.amount, 0);
    });

    test('acepta DTOs ya parseados (dobles de prueba del servicio)', () {
      final dto = PaymentHistoryDTO.fromJson(_row());

      expect(paymentHistoryFromResponse([dto]).single, same(dto));
    });
  });
}
