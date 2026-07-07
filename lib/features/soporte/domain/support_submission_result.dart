/// Resultado del envío de una solicitud de soporte. Port de
/// `SupportSubmissionResult` (domain/repository/SupportRequestRepository.kt).
sealed class SupportSubmissionResult {
  const SupportSubmissionResult();
}

class SupportSuccess extends SupportSubmissionResult {
  final String confirmationMessage;
  final String? ticketReference;

  const SupportSuccess(this.confirmationMessage, {this.ticketReference});
}

/// Error de red (sin conexión, timeout). Reintentable.
class SupportFailureNetwork extends SupportSubmissionResult {
  const SupportFailureNetwork();
}

/// Error del servidor. Probablemente reintentable.
class SupportFailureServer extends SupportSubmissionResult {
  final String message;
  const SupportFailureServer(this.message);
}

/// Error de validación detectado por el backend. NO reintentable.
class SupportFailureValidation extends SupportSubmissionResult {
  final String message;
  const SupportFailureValidation(this.message);
}

/// Cualquier otro error inesperado.
class SupportFailureUnknown extends SupportSubmissionResult {
  final String message;
  const SupportFailureUnknown(this.message);
}
