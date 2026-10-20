import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/features/impuestos/presentation/consulta_impuesto_screen.dart';

void main() {
  tearDown(() => TaxIntroRotation.resetTo(null));

  test('recorre los tres textos en orden y vuelve al primero', () {
    TaxIntroRotation.resetTo(0);

    final seen = [for (var i = 0; i < 4; i++) TaxIntroRotation.next()];

    expect(seen.sublist(0, 3), taxIntroTexts);
    expect(seen[3], taxIntroTexts[0]);
  });

  test(
    'nunca repite el mismo texto dos veces seguidas, arranque donde arranque',
    () {
      for (var start = 0; start < taxIntroTexts.length; start++) {
        TaxIntroRotation.resetTo(start);
        final a = TaxIntroRotation.next();
        final b = TaxIntroRotation.next();
        expect(a, isNot(b));
      }
    },
  );
}
