import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/services/api_providers.dart';
import '../../../core/telemetry/non_fatal_reporter.dart';
import '../../auth/application/auth_providers.dart';

/// Registro previo del pago en el historial (`POST api/PaymentHistory/`, status
/// `false`, statusType `2` = COMENZADA), puerto de `createHistoryPay` del
/// original. Lo usan la consulta de impuestos y el pago sin validación.
///
/// Hay que **esperarlo antes de crear la transacción**: si no, la fila puede
/// crearse después de que el usuario ya llegó a la pasarela, o no crearse, sin
/// que nadie lo note.
///
/// Es **best-effort** como en el original: si falla, el ciudadano igual puede
/// pagar. Pero el fallo deja rastro como no fatal (código, mensaje, trámite e
/// impuesto; nada personal) y un `pago_error` en analítica (etapa
/// `registro_historial`). Devuelve si el registro quedó hecho.
Future<bool> registerPaymentHistory(
  Ref ref, {
  required int municipalityId,
  required PaymentOrigin origin,
  required int amount,
  required String idImpuesto,
  required String factura,
  required String codigoEntidad,
  required int municipalityProceduresId,
}) async {
  final reporter = ref.read(nonFatalReporterProvider);
  final analytics = ref.read(analyticsServiceProvider);
  void logError({Object? error, String? reason}) => unawaited(
    analytics.logPaymentError(
      municipalityId: municipalityId,
      origin: origin,
      stage: PaymentStage.historyRegistration,
      error: error,
      reason: reason,
    ),
  );
  final trace = <String, Object?>{
    'municipalityProceduresId': municipalityProceduresId,
    'idimpuesto': idImpuesto,
  };
  try {
    final now = DateTime.now();
    final formattedDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final body = <String, dynamic>{
      'userId': ref.read(sessionProvider)?.id,
      'amount': amount,
      'paymentDate': formattedDate,
      'status': false,
      'municipalityProceduresId': municipalityProceduresId,
      'statusType': 2,
      'codigoEntidad': codigoEntidad,
      'factura': factura,
      'idimpuesto': idImpuesto,
    };
    final response = await ref
        .read(paymentHistoryApiServiceProvider)
        .createPaymentHistory(body);
    if (response.booleanStatus) return true;
    logError(reason: 'rechazado_${response.codeStatus}');
    reporter.report(
      'Registro del historial de pago rechazado',
      context: {
        'codeStatus': response.codeStatus,
        'sentencesError': response.sentencesError,
        ...trace,
      },
    );
    return false;
  } catch (e, stack) {
    // Un 400 de validación llega como `ValidationProblemDetails`, no como el
    // envelope, y no se puede leer como `ValidationResponseDTO`.
    logError(error: e);
    reporter.report(
      'Registro del historial de pago falló',
      context: {
        if (e is DioException) 'httpStatus': e.response?.statusCode,
        ...trace,
      },
      error: e,
      stackTrace: stack,
    );
    return false;
  }
}
