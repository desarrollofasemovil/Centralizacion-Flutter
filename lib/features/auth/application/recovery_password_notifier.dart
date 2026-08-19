import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/models/validation_response_extra_dto.dart';
import '../../../core/storage/user_preferences.dart';
import 'auth_providers.dart';

/// Estado de `RecoveryPasswordScreen` — puerto fiel de
/// `RecoveryPasswordUiState.kt`.
class RecoveryPasswordState {
  final String email;
  final bool loading;
  final bool emailError;
  final ValidationResponseExtraDto? sendCodeResponse;
  final bool showCodeSheet;
  final bool navigateToChangePassword;
  final String? errorMessage;
  final bool isCodeError;
  final int attempts;
  final int numbersOfRequests;
  final bool isBlockedButton;

  const RecoveryPasswordState({
    this.email = '',
    this.loading = false,
    this.emailError = false,
    this.sendCodeResponse,
    this.showCodeSheet = false,
    this.navigateToChangePassword = false,
    this.errorMessage,
    this.isCodeError = false,
    this.attempts = 0,
    this.numbersOfRequests = 2,
    this.isBlockedButton = false,
  });

  RecoveryPasswordState copyWith({
    String? email,
    bool? loading,
    bool? emailError,
    ValidationResponseExtraDto? sendCodeResponse,
    bool clearSendCodeResponse = false,
    bool? showCodeSheet,
    bool? navigateToChangePassword,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isCodeError,
    int? attempts,
    int? numbersOfRequests,
    bool? isBlockedButton,
  }) {
    return RecoveryPasswordState(
      email: email ?? this.email,
      loading: loading ?? this.loading,
      emailError: emailError ?? this.emailError,
      sendCodeResponse: clearSendCodeResponse
          ? null
          : (sendCodeResponse ?? this.sendCodeResponse),
      showCodeSheet: showCodeSheet ?? this.showCodeSheet,
      navigateToChangePassword:
          navigateToChangePassword ?? this.navigateToChangePassword,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isCodeError: isCodeError ?? this.isCodeError,
      attempts: attempts ?? this.attempts,
      numbersOfRequests: numbersOfRequests ?? this.numbersOfRequests,
      isBlockedButton: isBlockedButton ?? this.isBlockedButton,
    );
  }
}

/// Puerto de `RecoveryPasswordViewModel.kt`: envía el código de verificación
/// por correo (`GET api/Email/SendEmail/ValidationCode`), lo valida
/// localmente contra el `extraData` que devuelve el backend (no hay endpoint
/// de verificación en servidor — ver BACKEND §3.12) y, si coincide, marca al
/// usuario como logueado (`changeStatusUser`) y persiste la sesión para que
/// pueda cambiar su contraseña en el siguiente paso.
class RecoveryPasswordNotifier extends Notifier<RecoveryPasswordState> {
  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static const _fiveMinutesMs = 5 * 60 * 1000;

  @override
  RecoveryPasswordState build() => const RecoveryPasswordState();

  void onEmailChanged(String value) {
    state = state.copyWith(
      email: value,
      emailError: false,
      clearErrorMessage: true,
    );
  }

  bool _isValidEmail(String email) =>
      email.isNotEmpty && _emailRegex.hasMatch(email);

  /// Revisa si el bloqueo de 5 minutos por límite de intentos ya expiró.
  Future<void> checkIfCanUnblock() async {
    final savedTime =
        ref.read(userPreferencesProvider).getTimeBlockedSendEmail();
    if (savedTime == null) return;

    final diff = DateTime.now().millisecondsSinceEpoch - savedTime;
    if (diff >= _fiveMinutesMs) {
      await ref.read(userPreferencesProvider).clearTimeBlockedSendEmail();
      state = state.copyWith(
        isBlockedButton: false,
        numbersOfRequests: 3,
        clearErrorMessage: true,
      );
    } else {
      state = state.copyWith(isBlockedButton: true);
    }
  }

  Future<void> recoveryPassword() async {
    if (!_isValidEmail(state.email)) {
      state = state.copyWith(emailError: true);
      return;
    }

    state = state.copyWith(loading: true, clearErrorMessage: true);
    try {
      final result = await ref
          .read(sendEmailsApiServiceProvider)
          .sendEmailValidationCode(state.email)
          .timeout(const Duration(seconds: 10));

      if (!result.booleanStatus) {
        state = state.copyWith(
          sendCodeResponse: result,
          showCodeSheet: false,
          errorMessage: result.sentencesError,
        );
        return;
      }

      state = state.copyWith(sendCodeResponse: result, showCodeSheet: true);
    } on TimeoutException {
      state = state.copyWith(
        errorMessage:
            'El servidor tardó demasiado en responder. Intenta nuevamente más tarde.',
        showCodeSheet: false,
      );
    } catch (e) {
      state = state.copyWith(
        sendCodeResponse: ValidationResponseExtraDto(
          booleanStatus: false,
          sentencesError: 'Tenemos problemas de red: $e',
        ),
        showCodeSheet: false,
      );
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  /// Límite de intentos de envío (máx. 3 por bloqueo de 5 minutos).
  Future<void> controlRequestToSendEmail() async {
    final remaining = state.numbersOfRequests;
    if (remaining <= 0) {
      state = state.copyWith(isBlockedButton: true, showCodeSheet: false);
      await ref
          .read(userPreferencesProvider)
          .saveTimeBlockedSendEmail(DateTime.now().millisecondsSinceEpoch);
    } else {
      state = state.copyWith(numbersOfRequests: remaining - 1);
    }
  }

  /// El usuario cerró la hoja de código sin completarla (swipe/tap fuera) —
  /// se cierra la sesión que pudiera haber quedado a medias.
  Future<void> onModalCloseWithoutCompleting() async {
    state = state.copyWith(showCodeSheet: false);
    await ref.read(authRepositoryProvider).logout();
  }

  Future<void> validateCode(String code) async {
    final backendCode = state.sendCodeResponse?.extraData;
    if (backendCode == null) return;

    state = state.copyWith(
      loading: true,
      clearErrorMessage: true,
      isCodeError: false,
    );
    try {
      if (code != backendCode) {
        state = state.copyWith(
          errorMessage: 'El código ingresado no es correcto.',
          isCodeError: true,
          attempts: state.attempts + 1,
          showCodeSheet: false,
        );
        return;
      }

      final repo = ref.read(authRepositoryProvider);
      final user = await repo.getUserByEmail(state.email);
      if (user == null) {
        state = state.copyWith(
          sendCodeResponse: const ValidationResponseExtraDto(
            booleanStatus: false,
            sentencesError: 'Tenemos problemas con tu información',
          ),
          showCodeSheet: false,
        );
        return;
      }

      final changedStatus = await repo.setLoginStatus(user.id, true);
      if (!changedStatus.booleanStatus) {
        state = state.copyWith(
          sendCodeResponse: const ValidationResponseExtraDto(
            booleanStatus: false,
            sentencesError: 'Tenemos problemas con tu cambio de Estado',
          ),
          showCodeSheet: false,
        );
        return;
      }

      await ref.read(sessionProvider.notifier).setSession(user);
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      state = state.copyWith(showCodeSheet: false, navigateToChangePassword: true);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al validar código: $e',
        isCodeError: true,
      );
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  void resetNavigation() {
    state = state.copyWith(navigateToChangePassword: false);
  }
}

final recoveryPasswordNotifierProvider = NotifierProvider.autoDispose<
    RecoveryPasswordNotifier, RecoveryPasswordState>(
  RecoveryPasswordNotifier.new,
);
