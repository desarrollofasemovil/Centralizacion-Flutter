import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../data/google_auth_service.dart';
import 'auth_providers.dart';
import 'registration_draft.dart';

/// Resultado del flujo de Google que interpreta el bottom sheet.
enum GoogleAuthStatus {
  /// La cuenta existe en backend → se inició sesión.
  loggedIn,

  /// La cuenta no existe en backend → ir al wizard de registro (prellenado).
  goToRegister,

  /// El usuario canceló el OAuth de Google → no hacer nada.
  cancelled,

  /// Error real (red, token, etc.).
  error,
}

class GoogleAuthOutcome {
  const GoogleAuthOutcome(this.status, [this.message]);
  final GoogleAuthStatus status;
  final String? message;
}

/// Lógica de "Continuar con Google" — puerto adaptado de `LoginOptionsViewModel`,
/// con **creación diferida** del usuario Firebase para evitar usuarios fantasma:
/// solo se crea el usuario en Firebase cuando ya existe en backend (login). Para
/// cuentas nuevas se guarda un [RegistrationDraft] con perfil + tokens y se va al
/// registro; el usuario Firebase se crea al finalizar `createUser` (ver wizard).
class LoginOptionsController {
  LoginOptionsController(this._ref);

  final Ref _ref;

  Future<GoogleAuthOutcome> signInWithGoogle() async {
    final google = _ref.read(googleAuthServiceProvider);

    // 1. OAuth puro de Google — todavía NO se crea usuario en Firebase.
    final profile = await google.getGoogleProfile();
    if (profile == null || profile.email.isEmpty) {
      return const GoogleAuthOutcome(GoogleAuthStatus.cancelled);
    }

    try {
      // 2. El backend es la fuente de verdad: ¿ya existe este usuario?
      final api = _ref.read(authApiServiceProvider);
      final existing = await api.getUserByEmail(profile.email);

      if (existing != null) {
        // 2a. Existe → ahora sí creamos/confirmamos el usuario Firebase.
        await google.completeFirebaseSignIn(
          idToken: profile.idToken,
          accessToken: profile.accessToken,
        );
        await _ref.read(sessionProvider.notifier).setSession(existing);
        // Sesión única (como el base): tolerar fallo.
        try {
          await api.changeStatusUser(existing.id, true);
        } catch (_) {}
        return const GoogleAuthOutcome(GoogleAuthStatus.loggedIn);
      }

      // 2b. No existe → guardar borrador y mandar a registro. SIN crear usuario
      // Firebase todavía (se crea al finalizar el registro en backend).
      _ref.read(registrationDraftProvider.notifier).state = RegistrationDraft(
        firstName: profile.firstName,
        lastName: profile.lastName,
        email: profile.email,
        googleIdToken: profile.idToken,
        googleAccessToken: profile.accessToken,
      );
      return const GoogleAuthOutcome(GoogleAuthStatus.goToRegister);
    } catch (_) {
      return const GoogleAuthOutcome(
        GoogleAuthStatus.error,
        'No se pudo verificar tu cuenta. Intenta de nuevo.',
      );
    }
  }
}

final loginOptionsControllerProvider = Provider<LoginOptionsController>(
  (ref) => LoginOptionsController(ref),
);
