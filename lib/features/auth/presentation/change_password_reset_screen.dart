import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../application/auth_providers.dart';
import '../application/change_password_reset_notifier.dart';

/// "Ingresa tu nueva contraseña" — último paso del flujo de recuperación,
/// alcanzado tras validar el código de verificación. Puerto fiel de
/// `ChangeOnlyPasswordScreen.kt`.
class ChangePasswordResetScreen extends ConsumerStatefulWidget {
  const ChangePasswordResetScreen({super.key});

  @override
  ConsumerState<ChangePasswordResetScreen> createState() =>
      _ChangePasswordResetScreenState();
}

class _ChangePasswordResetScreenState
    extends ConsumerState<ChangePasswordResetScreen> {
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onSuccess() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (ctx.mounted && Navigator.of(ctx).canPop()) {
            Navigator.of(ctx).pop();
          }
        });
        final user = ref.read(sessionProvider);
        return ConfirmationDialog(
          title: '¡Éxito!',
          message:
              'Contraseña actualizada correctamente. Bienvenido de nuevo ${user?.firstName ?? ''}',
          icon: Icons.check_circle,
          onConfirm: () {},
          onDismiss: () {},
        );
      },
    );
    if (!mounted) return;
    ref.read(changePasswordResetNotifierProvider.notifier).resetSuccessState();
    // No existe un "MAIN_NAV_GRAPH" único en go_router: se deshace toda la
    // pila de rutas empujadas por el flujo (recuperar → código → nueva
    // contraseña) para volver a la pantalla original, ya con la sesión
    // activa (ver `RecoveryPasswordNotifier.validateCode`).
    while (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = ref.read(changePasswordResetNotifierProvider.notifier);
    final state = ref.watch(changePasswordResetNotifierProvider);
    final userId = ref.watch(sessionProvider)?.id;

    ref.listen<bool>(
      changePasswordResetNotifierProvider.select((s) => s.isSuccess),
      (prev, next) {
        if (next) _onSuccess();
      },
    );

    ref.listen<String?>(
      changePasswordResetNotifierProvider.select((s) => s.generalError),
      (prev, next) {
        if (next != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(next)));
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        titleSpacing: 0,
        title: const Text('Cambiar contraseña', style: TextStyle(color: Colors.white)),
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Center(
            child: Container(
              width: 35,
              height: 35,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back_ios_new,
                    size: 18, color: AppColors.primary),
                onPressed: () {
                  if (context.canPop()) context.pop();
                },
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Ingresa tu nueva contraseña',
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 25),
                _PasswordField(
                  controller: _newController,
                  label: 'Nueva Contraseña',
                  obscure: !_showNew,
                  errorText: state.newPasswordError,
                  onToggle: () => setState(() => _showNew = !_showNew),
                  onChanged: notifier.onNewPasswordChange,
                ),
                const SizedBox(height: 8),
                _PasswordField(
                  controller: _confirmController,
                  label: 'Confirmar contraseña',
                  obscure: !_showConfirm,
                  errorText: state.confirmPasswordError,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                  onChanged: notifier.onConfirmPasswordChange,
                ),
                const SizedBox(height: 15),
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
                          onPressed: (state.isLoading || userId == null)
                              ? null
                              : () => notifier.submitPasswordReset(userId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFF2196F3).withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Finalizar'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;
  final String? errorText;

  static const _errorRed = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.gray300),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.white),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _errorRed),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.white),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: AppColors.gray300,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
