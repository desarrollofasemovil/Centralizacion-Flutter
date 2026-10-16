import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/router/app_routes.dart';

void main() {
  test(
    'el extra de la pantalla de procesamiento lleva la URL en paymentUrl',
    () {
      final extra = AppRoutes.pagosProcessingExtra('https://pse.test/pago');
      // La misma clave que mandan impuestos y PSV y que lee la ruta.
      expect(AppRoutes.pagosProcessingUrlKey, 'paymentUrl');
      expect(extra, {'paymentUrl': 'https://pse.test/pago'});
    },
  );

  test('certificados navega a la pasarela con el extra compartido', () {
    // Guarda: el asistente mandaba `'url'` y la pasarela nunca abría.
    final source = File(
      'lib/features/certificados/presentation/certificates_wizard.dart',
    ).readAsStringSync();
    expect(source, contains('AppRoutes.pagosProcessingExtra('));
    expect(source, isNot(contains("'url':")));

    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    expect(router, contains('extra?[AppRoutes.pagosProcessingUrlKey]'));
  });
}
