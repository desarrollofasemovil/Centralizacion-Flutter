import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/footer_sponsors.dart';
import '../application/recovery_password_notifier.dart';
import 'widgets/verification_code_sheet.dart';

/// Recuperar contraseña — re-estilizado acorde a `RecoveryPasswordScreen.kt`:
/// fondo navy (`primarycolor`), logo centrado, campo blanco redondeado,
/// botones "Cancelar"/"Continuar" y footer de patrocinadores. Al enviar el
/// código con éxito abre `VerificationCodeSheet` (puerto de
/// `ShowModalVerificationCode.kt`) y, una vez validado, navega a
/// `ChangePasswordResetScreen` (puerto de `ChangeOnlyPasswordScreen.kt`).
class RecoveryPasswordScreen extends ConsumerStatefulWidget {
  const RecoveryPasswordScreen({super.key});

  @override
  ConsumerState<RecoveryPasswordScreen> createState() =>
      _RecoveryPasswordScreenState();
}

class _RecoveryPasswordScreenState extends ConsumerState<RecoveryPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sheetOpen = false;

  // Azul del botón "Continuar" del base (0xFF2196F3).
  static const _continueBlue = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recoveryPasswordNotifierProvider.notifier).checkIfCanUnblock();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _openVerificationSheet() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.gray300,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => VerificationCodeSheet(
        onCancel: () {
          Navigator.of(context).pop(true);
          if (context.canPop()) context.pop();
        },
      ),
    );
    _sheetOpen = false;
    if (!mounted) return;

    // Si el resultado no es `true`, la hoja se cerró por swipe/tap-fuera sin
    // completarse (ni "Cancelar" ni validación de código la cerraron
    // explícitamente) — replica `onDismissRequest` del original.
    if (result != true) {
      await ref
          .read(recoveryPasswordNotifierProvider.notifier)
          .onModalCloseWithoutCompleting();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('No terminaste el proceso, cerrando sesión...'),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(recoveryPasswordNotifierProvider.notifier);
    final state = ref.watch(recoveryPasswordNotifierProvider);

    if (_emailController.text != state.email) {
      _emailController.value = _emailController.value.copyWith(
        text: state.email,
        selection: TextSelection.collapsed(offset: state.email.length),
      );
    }

    ref.listen<bool>(
      recoveryPasswordNotifierProvider.select((s) => s.showCodeSheet),
      (prev, next) {
        if (next) _openVerificationSheet();
      },
    );

    ref.listen<bool>(
      recoveryPasswordNotifierProvider.select((s) => s.navigateToChangePassword),
      (prev, next) {
        if (next) {
          notifier.resetNavigation();
          context.push(AppRoutes.changePasswordReset);
        }
      },
    );

    final displayError = state.sendCodeResponse?.sentencesError.isNotEmpty == true
        ? state.sendCodeResponse!.sentencesError
        : state.errorMessage;
    final isErrorColor = state.sendCodeResponse?.booleanStatus == false ||
        state.isCodeError ||
        state.errorMessage != null;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      height: 140,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.primary),
                    onChanged: notifier.onEmailChanged,
                    decoration: InputDecoration(
                      hintText: 'Ingrese su correo',
                      hintStyle: const TextStyle(color: AppColors.gray600),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (!state.isBlockedButton)
                    const Text(
                      'Te enviaremos un código de seguridad a tu correo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              if (context.canPop()) context.pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: state.isBlockedButton
                                ? null
                                : () {
                                    notifier.recoveryPassword();
                                    notifier.controlRequestToSendEmail();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: state.isBlockedButton
                                  ? Colors.grey
                                  : _continueBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text('Continuar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (state.isBlockedButton)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Has alcanzado el límite de intentos',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFD32F2F),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Debes esperar 5 minutos para volver a intentarlo.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF5D4037)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (displayError != null)
                    Text(
                      displayError,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isErrorColor ? const Color(0xFFE53935) : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 40),
                  const FooterSponsors(color: Colors.white),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            if (state.loading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
