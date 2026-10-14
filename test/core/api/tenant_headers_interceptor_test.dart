import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/api/network_provider.dart';
import 'package:tramiapp_flutter/core/api/tenant_headers_interceptor.dart';
import 'package:tramiapp_flutter/core/flavor/flavor_config.dart';
import 'package:tramiapp_flutter/core/flavor/flavors.dart';
import 'package:tramiapp_flutter/core/utils/app_info.dart';

/// Adapter que no sale a la red: guarda la última petición y responde `{}`.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode({}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _prod = NetworkProvider.prodCentralizacionApiUrl;
const _dev = NetworkProvider.devCentralizacionApiUrl;

/// Dio con el interceptor apuntando a [centralizacionBaseUrl].
(Dio, _CapturingAdapter) _dio(String centralizacionBaseUrl) {
  final adapter = _CapturingAdapter();
  final dio = Dio()..httpClientAdapter = adapter;
  dio.interceptors.add(
    TenantHeadersInterceptor(
      centralizacionBaseUrl: () => centralizacionBaseUrl,
      appIdentifier: () => 'com.test.app',
      appVersion: () => '9.9.9',
      platform: () => 'android',
    ),
  );
  return (dio, adapter);
}

Future<Map<String, dynamic>> _headersFor(
  String centralizacionBaseUrl,
  String url,
) async {
  final (dio, adapter) = _dio(centralizacionBaseUrl);
  await dio.get<dynamic>(url);
  return adapter.last!.headers;
}

void main() {
  group('TenantHeadersInterceptor', () {
    for (final base in [_prod, _dev]) {
      test('agrega las 3 cabeceras hacia la API Centralízate ($base)', () async {
        final headers = await _headersFor(
          base,
          '${base}api/Municipality/GetInfoBy14',
        );

        expect(headers['X-App-Id'], 'com.test.app');
        expect(headers['X-App-Version'], '9.9.9');
        expect(headers['X-Platform'], 'android');
      });
    }

    // Las otras 5 base URLs son otros backends: no son la API multi-tenant.
    final otherApis = NetworkProvider.productionBaseUrls
        .where((url) => url != _prod)
        .toList();

    test('hay exactamente 5 base URLs ajenas a Centralízate', () {
      expect(otherApis, hasLength(5));
    });

    for (final other in otherApis) {
      test('no agrega cabeceras a $other', () async {
        final headers = await _headersFor(_prod, '${other}algo');

        expect(headers.containsKey('X-App-Id'), isFalse);
        expect(headers.containsKey('X-App-Version'), isFalse);
        expect(headers.containsKey('X-Platform'), isFalse);
      });
    }

    test('con el servidor de pruebas activo, producción no recibe cabeceras',
        () async {
      final headers = await _headersFor(_dev, '${_prod}api/Department');

      expect(headers.containsKey('X-App-Id'), isFalse);
    });

    test('distingue la API por prefijo de ruta detrás del proxy CORS de web',
        () async {
      const proxiedProd = 'http://localhost:8899/$_prod';
      const proxiedTax = 'http://localhost:8899/https://apidatamovil.1cero1.com/api/';

      final own = await _headersFor(proxiedProd, '${proxiedProd}api/Department');
      final tax = await _headersFor(proxiedProd, '${proxiedTax}Impuesto');

      expect(own['X-App-Id'], 'com.test.app');
      expect(tax.containsKey('X-App-Id'), isFalse);
    });

    test('sin plataforma conocida (web/desktop) no envía X-Platform', () async {
      final adapter = _CapturingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        TenantHeadersInterceptor(
          centralizacionBaseUrl: () => _prod,
          appIdentifier: () => 'com.test.app',
          appVersion: () => '1.0.0',
          platform: () => null,
        ),
      );

      await dio.get<dynamic>('${_prod}api/Department');

      expect(adapter.last!.headers['X-App-Id'], 'com.test.app');
      expect(adapter.last!.headers.containsKey('X-Platform'), isFalse);
    });

    test('por defecto toma los valores de FlavorConfig, AppInfo y la plataforma',
        () async {
      FlavorConfig.instance = flavorMunicipios;
      final adapter = _CapturingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(TenantHeadersInterceptor());

      await dio.get<dynamic>(
        '${NetworkProvider.centralizacionApiUrl}api/Department',
      );

      final headers = adapter.last!.headers;
      expect(headers['X-App-Id'], 'com.tramites1cero1.centralizacion');
      expect(headers['X-App-Version'], AppInfo.version);
      // `flutter test` simula Android salvo que se cambie la plataforma.
      expect(defaultTargetPlatform, TargetPlatform.android);
      expect(headers['X-Platform'], 'android');
    });

    test('currentPlatformHeader: android / ios / nada', () {
      final cases = {
        TargetPlatform.android: 'android',
        TargetPlatform.iOS: 'ios',
        TargetPlatform.macOS: null,
        TargetPlatform.windows: null,
      };
      for (final MapEntry(key: platform, value: expected) in cases.entries) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          TenantHeadersInterceptor.currentPlatformHeader(),
          expected,
          reason: '$platform',
        );
      }
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
