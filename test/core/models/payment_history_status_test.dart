import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/models/payment_history_dto.dart';

PaymentHistoryDTO _payment(int idStatusType, String statusType) =>
    PaymentHistoryDTO(
      id: 1,
      userFirtName: 'Ana',
      amount: 1000,
      paymentDate: '2026-10-13',
      status: false,
      idStatusType: idStatusType,
      alcaldia: 'Alcaldía',
      procedureName: 'Predial',
      statusType: statusType,
      idimpuesto: '1',
      factura: 'F-1',
      codigoEntidad: '001',
    );

/// Tabla `Availibity` de la API: 1 APROBADA, 2 COMENZADA, 3 FALLIDA,
/// 4 EXPIRADA. El port tenía los ids 2 y 3 cruzados: refrescar sincronizaba
/// los FALLIDA y deslizar ocultaba los COMENZADA.
void main() {
  test('solo COMENZADA se sincroniza al refrescar', () {
    expect(_payment(2, 'COMENZADA').isInProgress, isTrue);
    expect(_payment(1, 'APROBADA').isInProgress, isFalse);
    expect(_payment(3, 'FALLIDA').isInProgress, isFalse);
    expect(_payment(4, 'EXPIRADA').isInProgress, isFalse);
  });

  test('solo FALLIDA se puede ocultar', () {
    expect(_payment(3, 'FALLIDA').isFailed, isTrue);
    expect(_payment(2, 'COMENZADA').isFailed, isFalse);
    expect(_payment(1, 'APROBADA').isFailed, isFalse);
  });

  test('compara sin distinguir mayúsculas ni espacios', () {
    expect(_payment(2, ' comenzada ').isInProgress, isTrue);
    expect(_payment(3, 'Fallida').isFailed, isTrue);
  });
}
