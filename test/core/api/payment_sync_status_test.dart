import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/api/app_status.dart';
import 'package:tramiapp_flutter/core/api/global_error_interceptor.dart';
import 'package:tramiapp_flutter/core/api/network_provider.dart';
import 'package:tramiapp_flutter/core/api/services/payment_history_api_service.dart';

/// Responde siempre [statusCode] con un envelope `ValidationResponseDto`.
class _FakeApi implements HttpClientAdapter {
  _FakeApi(this.statusCode);

  final int statusCode;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    final ok = statusCode == 200;
    return ResponseBody.fromString(
      jsonEncode({
        'codeStatus': statusCode,
        'booleanStatus': ok,
        'sentencesError': ok
            ? 'Estado actualizado a APROBADA.'
            : 'Error de comunicación con el banco. Se reprogramará el siguiente intento.',
        'result': null,
      }),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Dio como el de la app (`validateStatus: (_) => true` + interceptor global).
(Dio, _FakeApi, List<AppStatus>) _dio(int statusCode) {
  final published = <AppStatus>[];
  final adapter = _FakeApi(statusCode);
  final dio = Dio(
    BaseOptions(
      baseUrl: NetworkProvider.prodCentralizacionApiUrl,
      validateStatus: (_) => true,
    ),
  )..httpClientAdapter = adapter;
  dio.interceptors.add(GlobalErrorInterceptor(published.add));
  return (dio, adapter, published);
}

void main() {
  group('PUT api/PaymentHistory/{id}/sync-status', () {
    test('el cliente generado usa la ruta del controlador', () async {
      final (dio, adapter, _) = _dio(200);
      final api = PaymentHistoryApiService(
        dio,
        baseUrl: NetworkProvider.prodCentralizacionApiUrl,
      );

      final result = await api.syncPaymentStatus(10);

      expect(adapter.last!.method, 'PUT');
      expect(
        adapter.last!.uri.toString(),
        'https://apicentralizate.1cero1.com/api/PaymentHistory/10/sync-status',
      );
      expect(result.booleanStatus, isTrue);
    });

    test('502 (banco no responde): devuelve el body y NO bloquea la app',
        () async {
      final (dio, _, published) = _dio(502);
      final api = PaymentHistoryApiService(
        dio,
        baseUrl: NetworkProvider.prodCentralizacionApiUrl,
      );

      final result = await api.syncPaymentStatus(10);

      expect(result.booleanStatus, isFalse);
      expect(result.codeStatus, 502);
      expect(published.where((s) => s.isBlocking), isEmpty);
    });

    test('control: un 5xx de cualquier otra petición sí bloquea', () async {
      final (dio, _, published) = _dio(502);

      await dio.get<dynamic>('api/Department');

      expect(published.single.isBlocking, isTrue);
      expect(published.single.type, AppStatusType.serverError);
    });
  });
}
