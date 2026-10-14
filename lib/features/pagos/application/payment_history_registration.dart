import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// impuesto; nada personal). Devuelve si el registro quedó hecho.
Future<bool> registerPaymentHistory(
  Ref ref, {
  required int amount,
  required String idImpuesto,
  required String factura,
  required String codigoEntidad,
  required int municipalityProceduresId,
}) async {
  final reporter = ref.read(nonFatalReporterProvider);
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
