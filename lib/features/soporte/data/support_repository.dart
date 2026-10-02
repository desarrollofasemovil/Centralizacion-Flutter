import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/emails_api_service.dart';
import '../../../core/models/email_dto.dart';
import '../domain/support_request.dart';
import '../domain/support_submission_result.dart';
import 'support_email_formatter.dart';
import 'support_email_provider.dart';

/// Capa de datos de Soporte. Construye el correo con [SupportEmailFormatter],
/// resuelve el destino con [SupportEmailProvider] y lo envía por el servicio de
/// emails ya existente. Port de `SupportRequestRepositoryImpl.kt`.
class SupportRepository {
  SupportRepository(this._emailApi)
      : _formatter = const SupportEmailFormatter(),
        _emailProvider = const SupportEmailProvider();

  final SendEmailsApiService _emailApi;
  final SupportEmailFormatter _formatter;
  final SupportEmailProvider _emailProvider;

  Future<SupportSubmissionResult> submit(SupportRequest request) async {
    try {
      final emailDto = EmailDto(
        to: _emailProvider.getSupportEmailFor(request.userContext.municipality),
        subject: _formatter.buildSubject(request),
        body: _formatter.buildBody(request),
      );

      final response = await _emailApi.sendEmail(emailDto);

      if (response.booleanStatus) {
        final message = response.sentencesError.trim().isNotEmpty
            ? response.sentencesError
            : 'Tu solicitud fue enviada correctamente. Recibirás respuesta entre 3 y 15 días hábiles.';
        return SupportSuccess(message);
      }
      return SupportFailureServer(
        response.sentencesError.trim().isNotEmpty
            ? response.sentencesError
            : 'No pudimos enviar tu solicitud. Inténtalo nuevamente.',
      );
    } on DioException catch (e) {
      // Fallos de red explícitos (sin conexión, timeout).
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const SupportFailureNetwork();
      }
      return SupportFailureUnknown(
        e.message ?? 'Error inesperado al enviar la solicitud.',
      );
    } catch (_) {
      return const SupportFailureUnknown(
          'Error inesperado al enviar la solicitud.');
    }
  }
}

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepository(ref.watch(sendEmailsApiServiceProvider)),
);
