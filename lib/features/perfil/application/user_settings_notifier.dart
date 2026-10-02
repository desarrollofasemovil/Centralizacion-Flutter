import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/emails_api_service.dart';
import '../../../core/models/email_dto.dart';
import '../../../core/storage/user_preferences.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/google_auth_service.dart';
import '../data/user_account_repository.dart';

/// Estado del formulario de cambio de contraseña. Port de `PasswordFormState`.
class PasswordFormState {
  final String current;
  final String newPass;
  final String confirm;
  final String? currentError;
  final String? newError;
  final String? confirmError;
  final bool isSaving;

  const PasswordFormState({
    this.current = '',
    this.newPass = '',
    this.confirm = '',
    this.currentError,
    this.newError,
    this.confirmError,
    this.isSaving = false,
  });

  bool get isValid =>
      current.isNotEmpty &&
      newPass.isNotEmpty &&
      confirm.isNotEmpty &&
      currentError == null &&
      newError == null &&
      confirmError == null;

  PasswordFormState copyWith({
    String? current,
    String? newPass,
    String? confirm,
    String? currentError,
    String? newError,
    String? confirmError,
    bool? isSaving,
    bool clearCurrentError = false,
    bool clearNewError = false,
    bool clearConfirmError = false,
  }) {
    return PasswordFormState(
      current: current ?? this.current,
      newPass: newPass ?? this.newPass,
      confirm: confirm ?? this.confirm,
      currentError: clearCurrentError
          ? null
          : (currentError ?? this.currentError),
      newError: clearNewError ? null : (newError ?? this.newError),
      confirmError: clearConfirmError
          ? null
          : (confirmError ?? this.confirmError),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Estado de la pantalla de Ajustes. Port del subconjunto de `UserSettingsUiState`.
class UserSettingsState {
  final PasswordFormState passwordForm;
  final bool remindersActive;
  final bool sendEmailActive;
  final bool isLoggingOut;
  final bool isDeleting;

  // Eventos transitorios (consumidos por la pantalla).
  final String? message;
  final bool passwordChanged;
  final bool navigateToWelcome;

  const UserSettingsState({
    this.passwordForm = const PasswordFormState(),
    this.remindersActive = true,
    this.sendEmailActive = false,
    this.isLoggingOut = false,
    this.isDeleting = false,
    this.message,
    this.passwordChanged = false,
    this.navigateToWelcome = false,
  });

  UserSettingsState copyWith({
    PasswordFormState? passwordForm,
    bool? remindersActive,
    bool? sendEmailActive,
    bool? isLoggingOut,
    bool? isDeleting,
    String? message,
    bool? passwordChanged,
    bool? navigateToWelcome,
    bool clearMessage = false,
  }) {
    return UserSettingsState(
      passwordForm: passwordForm ?? this.passwordForm,
      remindersActive: remindersActive ?? this.remindersActive,
      sendEmailActive: sendEmailActive ?? this.sendEmailActive,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      isDeleting: isDeleting ?? this.isDeleting,
      message: clearMessage ? null : (message ?? this.message),
      passwordChanged: passwordChanged ?? this.passwordChanged,
      navigateToWelcome: navigateToWelcome ?? this.navigateToWelcome,
    );
  }
}

/// Lógica de Ajustes. Port del subconjunto de `UserSettingsViewModel`.
class UserSettingsNotifier extends Notifier<UserSettingsState> {
  UserAccountRepository get _repo => ref.read(userAccountRepositoryProvider);
  UserPreferences get _prefs => ref.read(userPreferencesProvider);
  SendEmailsApiService get _emailApi => ref.read(sendEmailsApiServiceProvider);
  GoogleAuthService get _google => ref.read(googleAuthServiceProvider);

  @override
  UserSettingsState build() {
    return UserSettingsState(
      remindersActive: _prefs.remindersIsVisible(),
      sendEmailActive: _prefs.remindersSendIsVisible(),
    );
  }

  // ---------------------------------------------------------------------------
  // Cambio de contraseña
  // ---------------------------------------------------------------------------
  /// Reinicia el formulario (al abrir el diálogo de cambio de contraseña).
  void resetPasswordForm() =>
      state = state.copyWith(passwordForm: const PasswordFormState());

  void onPasswordInput(String field, String value) {
    final form = state.passwordForm;
    final next = switch (field) {
      'current' =>
        value.trim().isEmpty
            ? form.copyWith(current: value, currentError: 'Campo requerido')
            : form.copyWith(current: value, clearCurrentError: true),
      'new' =>
        value.length < 8
            ? form.copyWith(newPass: value, newError: 'Mínimo 8 caracteres')
            : form.copyWith(newPass: value, clearNewError: true),
      'confirm' =>
        value != form.newPass
            ? form.copyWith(confirm: value, confirmError: 'No coinciden')
            : form.copyWith(confirm: value, clearConfirmError: true),
      _ => form,
    };
    state = state.copyWith(passwordForm: next);
  }

  Future<void> submitChangePassword() async {
    final form = state.passwordForm;
    final user = ref.read(sessionProvider);
    if (user == null || !form.isValid) return;

    state = state.copyWith(passwordForm: form.copyWith(isSaving: true));

    try {
      final response = await _repo.updatePassword(
        user.id,
        form.current,
        form.newPass,
      );
      if (response.booleanStatus) {
        // Correo de confirmación (best-effort).
        try {
          await _emailApi.sendEmail(
            EmailDto(
              to: user.email,
              subject: 'Cambio de contraseña',
              body: 'Tu contraseña ha sido actualizada.',
            ),
          );
        } catch (_) {}
        state = state.copyWith(
          passwordForm: const PasswordFormState(),
          message: 'Contraseña actualizada exitosamente',
          passwordChanged: true,
        );
      } else {
        state = state.copyWith(
          passwordForm: form.copyWith(isSaving: false),
          message: response.sentencesError,
        );
      }
    } catch (_) {
      state = state.copyWith(
        passwordForm: form.copyWith(isSaving: false),
        message: 'No se pudo actualizar la contraseña',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Notificaciones
  // ---------------------------------------------------------------------------
  Future<void> toggleReminders(bool active) async {
    await _prefs.saveRemindersVisible(active);
    state = state.copyWith(remindersActive: active);
  }

  Future<void> toggleSendEmail(bool active) async {
    await _prefs.saveRemindersSendVisible(active);
    state = state.copyWith(sendEmailActive: active);
  }

  // ---------------------------------------------------------------------------
  // Cambio de municipio
  // ---------------------------------------------------------------------------
  Future<void> confirmChangeLocation() async {
    await _prefs.clearCurrentMunicipality();
    state = state.copyWith(navigateToWelcome: true);
  }

  // ---------------------------------------------------------------------------
  // Sesión
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    state = state.copyWith(isLoggingOut: true);
    await ref.read(sessionProvider.notifier).logout();
    await _google.signOut();
    state = state.copyWith(isLoggingOut: false, navigateToWelcome: true);
  }

  Future<void> deleteAccount() async {
    final user = ref.read(sessionProvider);
    if (user == null) return;

    state = state.copyWith(isDeleting: true);
    try {
      final result = await _repo.deleteUser(user.id);
      if (result.booleanStatus) {
        // Limpieza de Firebase / Google (best-effort).
        try {
          await FirebaseAuth.instance.currentUser?.delete();
        } catch (_) {}
        await _google.signOut();
        await ref.read(sessionProvider.notifier).logout();
        state = state.copyWith(
          isDeleting: false,
          message: 'Cuenta eliminada',
          navigateToWelcome: true,
        );
      } else {
        state = state.copyWith(
          isDeleting: false,
          message: result.sentencesError,
        );
      }
    } catch (_) {
      state = state.copyWith(
        isDeleting: false,
        message: 'No se pudo eliminar la cuenta',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Consumo de eventos transitorios
  // ---------------------------------------------------------------------------
  void consumeMessage() => state = state.copyWith(clearMessage: true);
  void consumePasswordChanged() =>
      state = state.copyWith(passwordChanged: false);
  void consumeNavigation() => state = state.copyWith(navigateToWelcome: false);
}

final userSettingsNotifierProvider =
    NotifierProvider<UserSettingsNotifier, UserSettingsState>(
      UserSettingsNotifier.new,
    );
