import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Perfil obtenido del OAuth de Google **sin** crear todavía un usuario en
/// Firebase Auth. Lleva los tokens para poder completar el `signInWithCredential`
/// más tarde (cuando ya exista el registro en backend) — ver
/// [GoogleAuthService.completeFirebaseSignIn].
class GoogleProfile {
  const GoogleProfile({
    required this.email,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.idToken,
    required this.accessToken,
  });

  final String email;
  final String displayName;
  final String firstName;
  final String lastName;
  final String? idToken;
  final String? accessToken;
}

/// Servicio de Google Sign-In (único uso de Firebase Auth en la app, BACKEND §5).
///
/// ⭐ Para evitar "usuarios fantasma" en Firebase Auth, el flujo se parte en dos:
///  1. [getGoogleProfile] hace **solo** el OAuth de Google (no crea usuario
///     Firebase) y devuelve el perfil + tokens.
///  2. [completeFirebaseSignIn] llama `signInWithCredential` (crea/confirma el
///     usuario Firebase) y se invoca **solo** cuando el usuario ya existe en
///     backend (login) o cuando `createUser` tuvo éxito (registro).
class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize();
    } catch (_) {
      // initialize() es idempotente en la práctica; si ya estaba inicializado
      // o la plataforma lo resuelve por config, seguimos.
    }
    _initialized = true;
  }

  /// Paso 1 — OAuth puro de Google. Devuelve null si el usuario cancela o falla
  /// (en ese caso **no** se crea ningún usuario en Firebase).
  Future<GoogleProfile?> getGoogleProfile() async {
    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      final googleAuth = account.authentication;
      final authorization =
          await account.authorizationClient.authorizationForScopes(
        const ['email', 'profile'],
      );

      final parts = account.displayName?.trim().split(RegExp(r'\s+')) ?? const [];
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      return GoogleProfile(
        email: account.email,
        displayName: account.displayName ?? '',
        firstName: firstName,
        lastName: lastName,
        idToken: googleAuth.idToken,
        accessToken: authorization?.accessToken,
      );
    } catch (_) {
      // Cancelación o error → no-op (no se toca Firebase Auth).
      return null;
    }
  }

  /// Paso 2 — crea/confirma el usuario en Firebase Auth con la credencial Google.
  /// Solo se llama cuando ya está justificado (existe en backend / registro OK).
  Future<UserCredential?> completeFirebaseSignIn({
    required String? idToken,
    required String? accessToken,
  }) async {
    try {
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>(
  (ref) => GoogleAuthService(),
);
