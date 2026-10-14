import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_status.dart';
import 'debug_http_log_interceptor.dart';
import 'global_error_interceptor.dart';
import 'network_provider.dart';
import 'tenant_headers_interceptor.dart';

/// Cliente [Dio] único compartido por todos los servicios — equivalente al
/// `OkHttpClient` único que `ApiFactory` reutiliza para las 6 base URLs
/// (BACKEND §1). Timeouts de 40s, cabeceras multi-tenant hacia la API
/// Centralízate ([TenantHeadersInterceptor]), log solo en debug
/// ([DebugHttpLogInterceptor]) y el
/// [GlobalErrorInterceptor] enganchado al estado global.
///
/// `validateStatus: (_) => true`: el éxito se evalúa por `booleanStatus`, no por
/// el código HTTP (CONVENCIONES §4); por eso no dejamos que Dio lance en 4xx/5xx
/// y el repositorio inspecciona el body.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: NetworkProvider.centralizacionApiUrl, // Retrofit "principal"
      connectTimeout: const Duration(seconds: 40),
      receiveTimeout: const Duration(seconds: 40),
      sendTimeout: const Duration(seconds: 40),
      validateStatus: (_) => true,
    ),
  );

  // Antes del log para que las cabeceras salgan en el log de debug.
  dio.interceptors.add(TenantHeadersInterceptor());

  // Solo debug y solo la API Centralízate; sin bodies de petición ni respuestas
  // con datos de la cuenta (ver `DebugHttpLogInterceptor`).
  if (kDebugMode) dio.interceptors.add(DebugHttpLogInterceptor());

  dio.interceptors.add(
    GlobalErrorInterceptor(
      (status) => ref.read(appStatusProvider.notifier).updateStatus(status),
    ),
  );

  return dio;
});

/// Factory de servicios por base URL. Igual que `ApiFactory.createService`,
/// **reutiliza el mismo [Dio]** y solo cambia la base URL del servicio Retrofit.
///
/// Uso (cuando existan los servicios retrofit, Fase 1):
/// ```dart
/// final authApi = AuthApiService(
///   ref.read(dioProvider),
///   baseUrl: NetworkProvider.centralizacionApiUrl,
/// );
/// ```
/// Cada servicio recibe `ref.read(dioProvider)` y su `NetworkProvider.*Url`.
