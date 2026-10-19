import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/features/impuestos/domain/tax.dart';

Tax _tax(String dueDate) => Tax(
  entity: 'Alcaldía',
  entityCode: '05030',
  document: '123',
  name: 'Ana',
  taxName: 'Predial',
  taxId: 1,
  value: 25000,
  invoice: 'FAC-1',
  reference: 'REF',
  dueDate: dueDate,
  queryField: '',
);

void main() {
  group('parseDueDate (mismos formatos que Tax.kt)', () {
    final cases = {
      '31/10/2026': DateTime(2026, 10, 31), // dd/MM/yyyy
      '2026/31/10': DateTime(2026, 10, 31), // yyyy/dd/MM
      '10/2026/31': DateTime(2026, 10, 31), // MM/yyyy/dd
      '31/2025/12': DateTime(2025, 12, 31), // dd/yyyy/MM
      '2026/10/31': DateTime(2026, 10, 31), // yyyy/MM/dd
      ' 31/10/2026 ': DateTime(2026, 10, 31),
    };
    cases.forEach((input, expected) {
      test('"$input" → $expected', () {
        expect(Tax.parseDueDate(input), expected);
      });
    });

    test('lo que no encaja en ningún formato no se lee', () {
      expect(Tax.parseDueDate(''), isNull);
      expect(Tax.parseDueDate('31-10-2026'), isNull);
      expect(Tax.parseDueDate('32/13/2026'), isNull);
    });
  });

  group('isExpired', () {
    test('31/10/2026 no se lee como un año viejo (regresión)', () {
      // Antes: `yyyy/dd/MM` tolerante lo leía como 10/10/0199 → vencida.
      final date = Tax.parseDueDate('31/10/2026')!;
      expect(date.year, 2026);
    });

    test('fecha futura en cualquier formato: no vencida', () {
      for (final d in [
        '31/12/2999',
        '2999/31/12',
        '12/2999/31',
        '31/2999/12',
        '2999/12/31',
      ]) {
        expect(_tax(d).isExpired, isFalse, reason: d);
      }
    });

    test('fecha pasada: vencida', () {
      expect(_tax('01/01/2020').isExpired, isTrue);
      expect(_tax('2020/01/01').isExpired, isTrue);
    });

    test('hoy no está vencida', () {
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      expect(
        _tax('${two(now.day)}/${two(now.month)}/${now.year}').isExpired,
        isFalse,
      );
    });

    test('fecha ilegible: no se bloquea el pago (como el original)', () {
      expect(_tax('sin fecha').isExpired, isFalse);
    });
  });
}
