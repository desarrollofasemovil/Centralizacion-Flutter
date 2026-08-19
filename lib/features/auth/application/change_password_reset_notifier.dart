import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Puerto de `ChangePasswordUiState`/`ChangePasswordViewModel.kt` —
/// pantalla "Ingresa tu nueva contraseña" tras validar el código de
/// recuperación (NO confundir con `UserSettingsNotifier`, que cambia la
/// contraseña autenticado pidiendo la contraseña actual).
class ChangePasswordResetState {
  final String newPassword;
  final String confirmPassword;
  final String? newPasswordError;
  final String? confirmPasswordError;
  final bool isLoading;
  final bool isSuccess;
  final String? generalError;

  const ChangePasswordResetState({
    this.newPassword = '',
    this.confirmPassword = '',
    this.newPasswordError,
    this.confirmPasswordError,
    this.isLoading = false,
    this.isSuccess = false,
    this.generalError,
  });

  ChangePasswordResetState copyWith({
    String? newPassword,
    String? confirmPassword,
    String? newPasswordError,
    bool clearNewPasswordError = false,
    String? confirmPasswordError,
    bool clearConfirmPasswordError = false,
    bool? isLoading,
    bool? isSuccess,
    String? generalError,
    bool clearGeneralError = false,
  }) {
    return ChangePasswordResetState(
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      newPasswordError: clearNewPasswordError
          ? null
          : (newPasswordError ?? this.newPasswordError),
      confirmPasswordError: clearConfirmPasswordError
          ? null
          : (confirmPasswordError ?? this.confirmPasswordError),
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      generalError:
          clearGeneralError ? null : (generalError ?? this.generalError),
    );
  }
}

class ChangePasswordResetNotifier extends Notifier<ChangePasswordResetState> {
  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&+=¿?*._-]).{8,}$',
  );

  @override
  ChangePasswordResetState build() => const ChangePasswordResetState();

  void onNewPasswordChange(String value) {
    state = state.copyWith(
      newPassword: value,
      clearNewPasswordError: true,
      clearGeneralError: true,
    );
  }

  void onConfirmPasswordChange(String value) {
    state = state.copyWith(
      confirmPassword: value,
      clearConfirmPasswordError: true,
      clearGeneralError: true,
    );
  }

  Future<void> submitPasswordReset(int userId) async {
    final newPassword = state.newPassword;
    final confirmPassword = state.confirmPassword;

    String? newError;
    if (newPassword.isEmpty) {
      newError = 'El campo no puede estar vacío';
    } else if (newPassword.length < 8) {
      newError = 'Mínimo 8 caracteres';
    } else if (!_passwordRegex.hasMatch(newPassword)) {
      newError =
          'Debe tener 1 Mayúscula, 1 minúscula, 1 número y 1 carácter especial';
    }

    final confirmError =
        confirmPassword != newPassword ? 'Las contraseñas no coinciden' : null;

    if (newError != null || confirmError != null) {
      state = state.copyWith(
        newPasswordError: newError,
        clearNewPasswordError: newError == null,
        confirmPasswordError: confirmError,
        clearConfirmPasswordError: confirmError == null,
      );
      return;
    }

    state = state.copyWith(isLoading: true);
    final response = await ref
        .read(authRepositoryProvider)
        .updatePasswordByForget(userId, newPassword);

    if (response.booleanStatus) {
      state = state.copyWith(isLoading: false, isSuccess: true);
    } else {
      state = state.copyWith(
        isLoading: false,
        generalError: response.sentencesError,
      );
    }
  }

  void resetSuccessState() {
    state = state.copyWith(isSuccess: false);
  }
}

final changePasswordResetNotifierProvider = NotifierProvider.autoDispose<
    ChangePasswordResetNotifier, ChangePasswordResetState>(
  ChangePasswordResetNotifier.new,
);
