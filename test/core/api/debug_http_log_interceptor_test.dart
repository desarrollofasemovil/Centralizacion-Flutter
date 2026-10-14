import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/api/debug_http_log_interceptor.dart';
import 'package:tramiapp_flutter/core/api/network_provider.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body);

  final Object body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

const _api = NetworkProvider.prodCentralizacionApiUrl;

Future<List<String>> _logFor(
  String method,
  String url, {
  Object? data,
  Object response = const {'ok': true},
}) async {
  final lines = <String>[];
  final dio = Dio()..httpClientAdapter = _Adapter(response);
  dio.interceptors.add(
    DebugHttpLogInterceptor(centralizacionBaseUrl: () => _api, log: lines.add),
  );
  await dio.request<dynamic>(url, data: data, options: Options(method: method));
  return lines;
}

void main() {
  test('registra método, URL, código y body de respuesta de la API', () async {
    final lines = await _logFor(
      'POST',
      '${_api}api/PaymentHistory/',
      data: {'municipalityProceduresId': 3},
      response: {'codeStatus': 200, 'booleanStatus': true},
    );

    expect(lines.first, contains('--> POST ${_api}api/PaymentHistory/'));
    expect(lines.last, contains('<-- 200 POST'));
    expect(lines.last, contains('booleanStatus: true'));
  });

  test('nunca registra el body de la petición (el login lleva la contraseña)',
      () async {
    final lines = await _logFor(
      'POST',
      '${_api}api/Auth',
      data: {'email': 'ana@correo.co', 'password': 'S3creta!'},
    );

    final all = lines.join('\n');
    expect(all, isNot(contains('S3creta!')));
    expect(all, isNot(contains('ana@correo.co')));
  });

  test('oculta las respuestas de cuenta (traen el hash de la contraseña)', () async {
    final lines = await _logFor(
      'GET',
      '${_api}api/User/by-email/?email=x',
      response: {'password': 'hash-secreto'},
    );

    expect(lines.last, contains('<oculto>'));
    expect(lines.join('\n'), isNot(contains('hash-secreto')));
  });

  test('no registra otros backends (impuestos, PQRD, Google…)', () async {
    final lines = await _logFor(
      'GET',
      'https://apidatamovil.1cero1.com/api/Impuesto',
    );

    expect(lines, isEmpty);
  });
}
