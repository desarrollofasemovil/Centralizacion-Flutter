import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/theme/color_parser.dart';

void main() {
  group('parseColor (puerto fiel de DataMappers.parseColor)', () {
    test('hex ARGB con prefijo 0x', () {
      expect(parseColor('0xFF1565C0'), const Color(0xFF1565C0));
    });

    test('hex ARGB de 8 dígitos sin prefijo', () {
      expect(parseColor('FF1565C0'), const Color(0xFF1565C0));
    });

    test('6 dígitos (sin alpha) NO se rellenan → fallback', () {
      // El original exige exactamente 8 dígitos.
      expect(parseColor('1565C0'), kColorFallback);
    });

    test('null y vacío → fallback', () {
      expect(parseColor(null), kColorFallback);
      expect(parseColor('   '), kColorFallback);
    });

    test('no-hex → fallback', () {
      expect(parseColor('0xZZZZZZZZ'), kColorFallback);
    });

    test('fallback por campo (onPrimaryColorLight → negro)', () {
      expect(parseColor(null, fallback: const Color(0xFF000000)),
          const Color(0xFF000000));
    });

    test('fallback por defecto es Color.Gray (0xFF888888)', () {
      expect(kColorFallback, const Color(0xFF888888));
    });
  });
}
