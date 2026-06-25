import 'dart:convert';

import '../../../core/api/services/auth_api_service.dart';
import '../../../core/models/login_dto.dart';
import '../../../core/models/user_dto.dart';
import '../../../core/storage/user_preferences.dart';

/// Resultado del login nativo.
class LoginResult {
  final bool success;
  final String? message;
  final UserDTO? user;

  const LoginResult._(this.success, this.message, this.user);
  const LoginResult.success(UserDTO user) : this._(true, null, user);
  const LoginResult.failure(String message) : this._(false, message, null);
}

/// Login nativo (correo/clave) contra la API propia — NO usa Firebase Auth
/// (BACKEND §5.1). El éxito se evalúa por `booleanStatus`; el token viaja en
/// `sentencesError` cuando es exitoso.
class AuthRepository {
  AuthRepository(this._api, this._prefs);

  final AuthApiService _api;
  final UserPreferences _prefs;

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  Future<LoginResult> login(String email, String password) async {
    if (!_emailRegex.hasMatch(email)) {
      return const LoginResult.failure('Correo electrónico inválido.');
    }
    if (password.length < 8) {
      return const LoginResult.failure(
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

    final token = res.sentencesError; // el token viaja aquí en login exitoso
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
}
