import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'network_provider.dart';
import 'tenant_headers_interceptor.dart';

/// Log HTTP de **debug** para la API Centralízate: método, URL, cabeceras
/// multi-tenant, código y body de la respuesta. Sirve para diagnosticar contra
/// el servidor de pruebas (p. ej. qué responde `POST api/PaymentHistory/`).
///
/// Solo se registra en `kDebugMode` (ver `dioProvider`) y solo para la API
/// Centralízate; los demás backends no se registran. Por seguridad:
/// - **nunca** registra bodies de petición (login, contraseñas, datos del
///   ciudadano);
/// - omite el body de respuesta de `api/Auth` y `api/User/*`: las respuestas de
///   usuario incluyen el hash de la contraseña (API `docs/api/user.md`).
///
/// Reemplaza al `LogInterceptor(requestBody: true)` global, que imprimía el
/// body del login con la contraseña.
class DebugHttpLogInterceptor extends Interceptor {
  DebugHttpLogInterceptor({
    String Function()? centralizacionBaseUrl,
    void Function(String line)? log,
  }) : _baseUrl =
           centralizacionBaseUrl ?? (() => NetworkProvider.centralizacionApiUrl),
       _log = log ?? debugPrint;

  final String Function() _baseUrl;
  final void Function(String line) _log;

  static const _tenantHeaders = [
    TenantHeadersInterceptor.appIdHeader,
    TenantHeadersInterceptor.appVersionHeader,
    TenantHeadersInterceptor.platformHeader,
  ];

  bool _applies(RequestOptions o) =>
      NetworkProvider.isCentralizacionApi(o.uri, baseUrl: _baseUrl());

  static bool _hidesResponseBody(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.contains('/api/auth') || path.contains('/api/user/');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_applies(options)) {
      final tenant = [
        for (final h in _tenantHeaders)
          if (options.headers[h] != null) '$h: ${options.headers[h]}',
      ];
      _log('--> ${options.method} ${options.uri}  ${tenant.join('  ')}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logResponse(response.requestOptions, response.statusCode, response.data);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_applies(err.requestOptions)) {
      _log(
        '<-- ${err.requestOptions.method} ${err.requestOptions.uri} '
        'ERROR ${err.type.name}${err.message == null ? '' : ': ${err.message}'}',
      );
    }
    handler.next(err);
  }

  void _logResponse(RequestOptions options, int? status, Object? data) {
    if (!_applies(options)) return;
    final body = _hidesResponseBody(options.uri) ? '<oculto>' : '$data';
    _log('<-- $status ${options.method} ${options.uri}  $body');
  }
}
