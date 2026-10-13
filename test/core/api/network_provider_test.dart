import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/api/network_provider.dart';

/// Candado sobre las base URLs que se publican en producción.
///
/// No puede afirmar "en release se usa la de producción" ejecutándose, porque
/// `flutter test` corre siempre en modo debug. Lo que sí fija es lo que hace
/// verdadera esa afirmación por construcción:
///
/// * la constante de producción es EXACTAMENTE la URL oficial;
/// * ninguna base URL de producción es cleartext (iOS las bloquea por ATS y
///   Android solo permite HTTP al servidor de pruebas en el source set debug);
/// * el override está apagado por defecto, así que sin
///   `--dart-define=USE_DEV_SERVER=true` ni siquiera en debug se desvía.
void main() {
  group('NetworkProvider', () {
    test('la URL de producción es la oficial de Centralízate', () {
      expect(
        NetworkProvider.prodCentralizacionApiUrl,
        'https://apicentralizate.1cero1.com/',
      );
    });

    test('ninguna base URL de producción usa HTTP en claro', () {
      expect(NetworkProvider.productionBaseUrls, hasLength(6));
      for (final url in NetworkProvider.productionBaseUrls) {
        expect(
          url.startsWith('https://'),
          isTrue,
          reason: '$url no es HTTPS: iOS (ATS) y Android la bloquean.',
        );
      }
    });

    test('sin USE_DEV_SERVER se resuelve la URL de producción', () {
      // El test corre en debug, el único modo donde el override podría
      // aplicar; sin el `--dart-define` debe caer a producción.
      expect(NetworkProvider.isUsingDevServer, isFalse);
      expect(
        NetworkProvider.centralizacionApiUrl,
        NetworkProvider.prodCentralizacionApiUrl,
      );
    });
  });
}
