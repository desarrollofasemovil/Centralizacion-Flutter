import 'dart:io';

import 'package:dio/dio.dart';

import 'app_status.dart';

/// Publica un [AppStatus] en el estado global.
typedef AppStatusSink = void Function(AppStatus status);

/// Puerto de `GlobalErrorInterceptor.kt` (BACKEND §1.1).
///
/// Intercepta TODAS las respuestas/errores de red, publica un estado global y
/// **relanza** el error para que el notifier apague su `Loading`.
///
/// Como el [Dio] usa `validateStatus: (_) => true`, los códigos HTTP no lanzan:
/// los `5xx` llegan por [onResponse] (bloqueante) y aquí, en [onError], solo
/// caen los errores de conexión/timeout (no bloqueantes), igual que el `catch`
/// del OkHttp original.
class GlobalErrorInterceptor extends Interceptor {
  GlobalErrorInterceptor(this._publish);

  final AppStatusSink _publish;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final code = response.statusCode ?? 0;
    if (code >= 500 && code <= 599) {
      _publish(
        AppStatus(
          type: AppStatusType.serverError,
          title: 'El servicio no está disponible en este momento.',
          message: 'Problemas técnicos ($code).',
          isBlocking: true,
        ),
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // No tratamos la cancelación como error de servidor.
    if (err.type == DioExceptionType.cancel) {
      handler.next(err);
      return;
    }

    final (title, message) = _mapError(err);
    _publish(
      AppStatus(
        type: AppStatusType.serverError,
        title: title,
        message: message,
        isBlocking: false,
      ),
    );

    handler.next(err); // relanzar
  }

  (String, String) _mapError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ('Tiempo agotado', 'El servidor tardó demasiado en responder.');
      case DioExceptionType.connectionError:
        final underlying = err.error;
        final isDnsFailure = underlying is SocketException &&
            underlying.message.toLowerCase().contains('failed host lookup');
        if (isDnsFailure) {
          // Equivalente a UnknownHostException.
          return ('Sin conexión', 'Verifica tu conexión a internet.');
        }
        // Equivalente a ConnectException.
        return ('Servicio No Disponible', 'No se pudo establecer conexión.');
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        if (code >= 500 && code <= 599) {
          return (
            'El servicio no está disponible en este momento.',
            'Problemas técnicos ($code).',
          );
        }
        return (
          'Error de conexión',
          'No pudimos contactar con el servidor. Inténtalo más tarde.',
        );
      case DioExceptionType.badCertificate:
        return (
          'Error de conexión',
          'No pudimos contactar con el servidor. Inténtalo más tarde.',
        );
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return ('Error inesperado', err.message ?? 'Ocurrió un error desconocido.');
    }
  }
}
