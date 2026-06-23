import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_status.dart';
import 'global_error_interceptor.dart';
import 'network_provider.dart';

/// Cliente [Dio] único compartido por todos los servicios — equivalente al
/// `OkHttpClient` único que `ApiFactory` reutiliza para las 6 base URLs
/// (BACKEND §1). Timeouts de 40s, logging solo en debug y el
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

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

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
