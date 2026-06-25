// `StateProvider` vive en el import legacy desde Riverpod 3.x.
import 'package:flutter_riverpod/legacy.dart';

/// Borrador de registro — puerto de `saveRegistrationDraft` del base, extendido
/// con la credencial de Google. Cuando el login con Google detecta una cuenta
/// que **no** existe en backend, se guarda aquí el perfil para prellenar el
/// wizard y los tokens para completar el `signInWithCredential` (creación del
/// usuario Firebase) **solo** cuando `createUser` tenga éxito.
class RegistrationDraft {
  const RegistrationDraft({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.googleIdToken,
    this.googleAccessToken,
  });

  final String firstName;
  final String lastName;
  final String email;

  /// Tokens de Google para crear el usuario Firebase al finalizar el registro.
  final String? googleIdToken;
  final String? googleAccessToken;

  /// True si el borrador proviene de un login con Google (registro a completar).
  bool get isFromGoogle => googleIdToken != null;
}

/// Borrador activo (null = registro normal sin prellenado). En memoria; se limpia
/// al consumirse o cancelar el wizard.
final registrationDraftProvider = StateProvider<RegistrationDraft?>((ref) => null);

/// Señal de "registro completado sin sesión" — puerto del flag
/// `registration_success` del base. `MainScreen` la observa para reabrir el
/// bottom sheet de login al volver del wizard.
final registrationSuccessProvider = StateProvider<bool>((ref) => false);
