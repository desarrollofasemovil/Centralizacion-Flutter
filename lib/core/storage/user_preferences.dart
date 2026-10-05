import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ubicación guardada del usuario — puerto de `PreferenciaUsuario`
/// (`UserPreferencesRepositoryImpl`). Decide el `startDestination` al arrancar
/// (FRONTEND §1.1 / BACKEND §7.2).
class SavedLocation {
  final int departmentId;
  final int municipalityId;
  final String municipio;
  final bool guardado;

  const SavedLocation({
    this.departmentId = 0,
    this.municipalityId = 0,
    this.municipio = '',
    this.guardado = false,
  });
}

/// Persistencia local — puerto del subconjunto de núcleo de
/// `UserPreferencesRepository` (DataStore → shared_preferences).
///
/// **Conserva las MISMAS keys** que el proyecto Android para mantener la
/// semántica de los datos. Lo específico de módulos (caché de pagos,
/// PeopleInvitated, etc.) se porta en su feature correspondiente.
class UserPreferences {
  UserPreferences(this._prefs);

  final SharedPreferences _prefs;

  // Keys EXACTAS del proyecto Android (no cambiar).
  static const _kDepartmentId = 'departamento_seleccionado_id';
  static const _kMunicipalityId = 'municipio_seleccionado_id';
  static const _kMunicipio = 'municipio_seleccionado';
  static const _kGuardarUbicacion = 'guardar_preferencia';
  static const _kIsDarkTheme = 'is_dark_theme';
  static const _kModalFormCompleted = 'modal_form_completed';
  static const _kGuestUserData = 'guest_user_data';
  static const _kUserData = 'user_data';
  static const _kAuthToken = 'auth_token';
  static const _kRemindersVisible = 'remindersIsVible';
  static const _kRemindersSendByEmail = 'remindersSendByEmail';
  static const _kCoachmarkSeen = 'has_seen_notifications_coachmark';
  static const _kBlockedSendEmail = 'IS_BLOQUED_BOTTOM';
  // In-App Review: el Kotlin usaba un archivo aparte (`in_app_review_prefs`);
  // aquí se prefija porque comparte espacio con el resto de preferencias.
  static const _kReviewLoginCount = 'in_app_review_login_count';

  // ── Ubicación ──────────────────────────────────────────────────────────────
  SavedLocation getSavedLocation() => SavedLocation(
        departmentId: _prefs.getInt(_kDepartmentId) ?? 0,
        municipalityId: _prefs.getInt(_kMunicipalityId) ?? 0,
        municipio: _prefs.getString(_kMunicipio) ?? '',
        guardado: _prefs.getBool(_kGuardarUbicacion) ?? false,
      );

  Future<void> saveLocation({
    required int departmentId,
    required int municipalityId,
    required String municipio,
    required bool guardar,
  }) async {
    await _prefs.setInt(_kDepartmentId, departmentId);
    await _prefs.setInt(_kMunicipalityId, municipalityId);
    await _prefs.setString(_kMunicipio, municipio);
    await _prefs.setBool(_kGuardarUbicacion, guardar);
  }

  /// Igual que el original: NO borra `municipio_seleccionado_id`, solo
  /// departamento, nombre de municipio y el flag de guardado.
  Future<void> clearCurrentMunicipality() async {
    await _prefs.remove(_kDepartmentId);
    await _prefs.remove(_kMunicipio);
    await _prefs.remove(_kGuardarUbicacion);
  }

  // ── Tema ─────────────────────────────────────────────────────────────────
  bool isDarkTheme() => _prefs.getBool(_kIsDarkTheme) ?? false;

  Future<void> toggleTheme() async {
    await _prefs.setBool(_kIsDarkTheme, !isDarkTheme());
  }

  // ── Modal form ─────────────────────────────────────────────────────────────
  bool modalFormCompleted() => _prefs.getBool(_kModalFormCompleted) ?? false;

  Future<void> saveModalFormCompleted(bool completed) =>
      _prefs.setBool(_kModalFormCompleted, completed);

  // ── Datos de usuario invitado (JSON crudo hasta portar UserDTO) ─────────────
  String? getGuestUserDataJson() => _prefs.getString(_kGuestUserData);

  Future<void> saveGuestUserDataJson(String json) =>
      _prefs.setString(_kGuestUserData, json);

  // ── Sesión de usuario (UserDTO JSON, key 'user_data') ────────────────────────
  String? getUserSessionJson() => _prefs.getString(_kUserData);

  Future<void> saveUserSessionJson(String json) =>
      _prefs.setString(_kUserData, json);

  /// Cierra la sesión: borra los datos del usuario y el token.
  Future<void> clearUserSession() async {
    await _prefs.remove(_kUserData);
    await _prefs.remove(_kAuthToken);
  }

  // ── Token de auth ──────────────────────────────────────────────────────────
  /// Devuelve cadena vacía si no hay token. (El original devolvía la cadena
  /// literal "null" por un `toString()` sobre null — aquí se corrige a '').
  String getAuthToken() => _prefs.getString(_kAuthToken) ?? '';

  Future<void> saveAuthToken(String token) =>
      _prefs.setString(_kAuthToken, token);

  // ── Recordatorios (flags de visibilidad) ────────────────────────────────────
  bool remindersIsVisible() => _prefs.getBool(_kRemindersVisible) ?? true;

  Future<void> saveRemindersVisible(bool isActive) =>
      _prefs.setBool(_kRemindersVisible, isActive);

  bool remindersSendIsVisible() => _prefs.getBool(_kRemindersSendByEmail) ?? false;

  Future<void> saveRemindersSendVisible(bool isActive) =>
      _prefs.setBool(_kRemindersSendByEmail, isActive);

  // ── Coachmark de notificaciones ──────────────────────────────────────────────
  bool hasSeenNotificationsCoachmark() =>
      _prefs.getBool(_kCoachmarkSeen) ?? false;

  Future<void> markNotifCoachmarkSeen() =>
      _prefs.setBool(_kCoachmarkSeen, true);

  // ── Bloqueo de envío de email (timestamp en millis) ──────────────────────────
  int? getTimeBlockedSendEmail() => _prefs.getInt(_kBlockedSendEmail);

  Future<void> saveTimeBlockedSendEmail(int millis) =>
      _prefs.setInt(_kBlockedSendEmail, millis);

  Future<void> clearTimeBlockedSendEmail() => _prefs.remove(_kBlockedSendEmail);

  // ── In-App Review: inicios de sesión nativos acumulados ─────────────────────
  int reviewLoginCount() => _prefs.getInt(_kReviewLoginCount) ?? 0;

  Future<void> incrementReviewLoginCount() =>
      _prefs.setInt(_kReviewLoginCount, reviewLoginCount() + 1);
}

/// Instancia de [SharedPreferences]. **Se sobreescribe en `bootstrap`** tras
/// `SharedPreferences.getInstance()`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider debe sobreescribirse en bootstrap.',
  ),
);

final userPreferencesProvider = Provider<UserPreferences>(
  (ref) => UserPreferences(ref.watch(sharedPreferencesProvider)),
);
