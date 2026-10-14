import 'dart:convert';

import '../../../core/api/services/auth_api_service.dart';
import '../../../core/models/login_dto.dart';
import '../../../core/models/update_password_by_forget_dto.dart';
import '../../../core/models/user_dto.dart';
import '../../../core/models/validation_response_dto.dart';
import '../../../core/storage/user_preferences.dart';

/// Resultado del login nativo.
class LoginResult {
  final bool success;
  final String? message;
  final UserDTO? user;

  /// El fallo es de validación local (correo/clave mal formados), no del
  /// backend. La UI lo muestra bajo el campo; el del backend va en diálogo.
  final bool invalidInput;

  const LoginResult._(
    this.success,
    this.message,
    this.user, {
    this.invalidInput = false,
  });
  const LoginResult.success(UserDTO user) : this._(true, null, user);
  const LoginResult.failure(String message) : this._(false, message, null);
  const LoginResult.invalidInput(String message)
    : this._(false, message, null, invalidInput: true);
}

/// Login nativo (correo/clave) contra la API propia — NO usa Firebase Auth
/// (BACKEND §5.1). El éxito se evalúa por `booleanStatus`.
///
/// `POST api/Auth` **no emite token** (API `docs/api/auth.md`): solo valida
/// credenciales, y en éxito `sentencesError` es el mensaje "Inicio de sesión
/// exitoso". Aun así se guarda en `auth_token` como hacía el Kotlin; nada lo
/// lee (`getAuthToken()` no tiene llamadas). Queda como seguimiento quitarlo.
class AuthRepository {
  AuthRepository(this._api, this._prefs);

  final AuthApiService _api;
  final UserPreferences _prefs;

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  Future<LoginResult> login(String email, String password) async {
    if (!_emailRegex.hasMatch(email)) {
      return const LoginResult.invalidInput('Correo electrónico inválido.');
    }
    if (password.length < 8) {
      return const LoginResult.invalidInput(
        'La contraseña debe tener al menos 8 caracteres.',
      );
    }

    final res = await _api.login(LoginDTO(email: email, password: password));
    if (!res.booleanStatus) {
      return LoginResult.failure(
        res.sentencesError.isNotEmpty
            ? res.sentencesError
            : 'No se pudo iniciar sesión.',
      );
    }

    // No es un token: es el mensaje de éxito del login (ver doc de la clase).
    final token = res.sentencesError;
    final user = await _api.getUserByEmail(email);
    if (user == null) {
      return const LoginResult.failure('Usuario no encontrado.');
    }

    await _prefs.saveUserSessionJson(jsonEncode(user.toJson()));
    await _prefs.saveAuthToken(token);
    return LoginResult.success(user);
  }

  /// Persiste una sesión a partir de un [UserDTO] ya obtenido (p. ej. login con
  /// Google, donde el usuario viene de `getUserByEmail`). El login con Google
  /// NO usa token nativo, así que solo guardamos el usuario.
  Future<void> persistSession(UserDTO user) async {
    await _prefs.saveUserSessionJson(jsonEncode(user.toJson()));
  }

  /// Usuario de la sesión persistida (o null si no hay sesión).
  UserDTO? currentUser() {
    final json = _prefs.getUserSessionJson();
    if (json == null) return null;
    return UserDTO.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> logout() => _prefs.clearUserSession();

  /// Usuario completo por correo — usado en recuperación de contraseña tras
  /// validar el código (`RecoveryPasswordViewModel.validateCode`).
  Future<UserDTO?> getUserByEmail(String email) => _api.getUserByEmail(email);

  /// Cambia `loginStatus` del usuario (sesión única) — equivalente a
  /// `AuthRepository.getOutUser` del original.
  Future<ValidationResponseDTO> setLoginStatus(int userId, bool status) =>
      _api.changeStatusUser(userId, status);

  /// Recuperación por olvido — `updatePasswordUserByForget` del original.
  Future<ValidationResponseDTO> updatePasswordByForget(
    int userId,
    String newPassword,
  ) =>
      _api.updatePasswordByForget(
        userId,
        UpdatePasswordByForgetDto(newPassword: newPassword),
      );
}
