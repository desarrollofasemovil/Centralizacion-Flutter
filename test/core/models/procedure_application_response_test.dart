import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/models/procedure_application_response.dart';

void main() {
  test(
    'Estado booleano (como responde tramitesservices) no rompe el parseo',
    () {
      final ok = ProcedureApplicationResponse.fromJson({
        'Estado': true,
        'Ticket': 'TCK-00123',
        'Mensaje': null,
      });
      expect(ok.estado, isTrue);
      expect(ok.ticket, 'TCK-00123');

      final ko = ProcedureApplicationResponse.fromJson({
        'Estado': false,
        'Ticket': '',
        'Mensaje': 'Sin cupo',
      });
      expect(ko.estado, isFalse);
      expect(ko.mensaje, 'Sin cupo');
    },
  );

  test('también acepta "true"/"false" como texto y Ticket numérico', () {
    expect(
      ProcedureApplicationResponse.fromJson({
        'Estado': 'true',
        'Ticket': 7,
      }).estado,
      isTrue,
    );
    final r = ProcedureApplicationResponse.fromJson({
      'Estado': 'false',
      'Ticket': 123,
    });
    expect(r.estado, isFalse);
    expect(r.ticket, '123');
  });
}
