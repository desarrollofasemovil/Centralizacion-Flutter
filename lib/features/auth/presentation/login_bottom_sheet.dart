import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/review/review_prompt_service.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_providers.dart';
import '../application/login_options_controller.dart';
import '../application/registration_draft.dart';
import '../data/google_auth_service.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/footer_sponsors.dart';
import '../../../core/widgets/important_alert_dialog.dart';
import '../../../core/widgets/timed_dialog.dart';

/// Resultado con el que se cierra el sheet, para que el llamador navegue/avise
/// usando el contexto de la página (no el del sheet, que ya no existe tras pop).
/// `loggedIn` es el login nativo (correo/clave); el de Google va aparte porque
/// no cuenta para la reseña de la tienda (igual que en el Kotlin).
enum _SheetResult { loggedIn, loggedInWithGoogle, goToRegister, recover }

/// Cuánto dura "Inicio de sesión exitoso" antes de cerrarse solo: 2 s en
/// `MainScreen.kt` / `HistoryPayScreen.kt` (los `LaunchedEffect` con
/// `delay(2000L)`), 1,5 s en `UserSettingsScreen.kt`.
const loginSuccessDialogDuration = Duration(seconds: 2);

/// "No se pudo iniciar sesión" se borra a los 2 s (`AuthScreen.kt` limpia la
/// respuesta con `delay(2000)` + `clearResponse()`).
const _loginErrorDialogDuration = Duration(seconds: 2);

/// Aviso "No pudimos completar el inicio de sesión con Google…" antes de ir al
/// registro (`delay(3200L)` en el `LoginEvent.NavigateToRegister` del base).
const _googleFallbackDelay = Duration(milliseconds: 3200);

/// Muestra el ModalBottomSheet de login (opciones + email) — puerto del
/// `ModalBottomSheet` que el base hospeda en `MainScreen.kt` (color `Gray300`).
///
/// [successDialogDuration]: ver [loginSuccessDialogDuration].
Future<void> showLoginBottomSheet(
  BuildContext context, {
  Duration successDialogDuration = loginSuccessDialogDuration,
}) async {
  final result = await showModalBottomSheet<_SheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.gray300,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _LoginSheetContent(),
  );

  if (!context.mounted) return;
  switch (result) {
    case _SheetResult.loggedIn || _SheetResult.loggedInWithGoogle:
      // Como el original: sin botones, se cierra solo (o tocando fuera).
      await showDialog<void>(
        context: context,
        builder: (ctx) => TimedDialog(
          duration: successDialogDuration,
          child: ConfirmationDialog(
            title: 'Inicio de sesión exitoso',
            message: 'Has iniciado sesión correctamente',
            icon: Icons.check_circle,
            onConfirm: () => Navigator.of(ctx).pop(),
            onDismiss: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
      // Tras cerrar el diálogo, con la pantalla de destino ya visible (el
      // Kotlin lo consume en MainScreen). Fuera del sheet: ese widget ya no
      // existe.
      if (result == _SheetResult.loggedIn && context.mounted) {
        unawaited(
          ProviderScope.containerOf(context, listen: false)
              .read(reviewPromptServiceProvider)
              .onSuccessfulLogin(),
        );
      }
    case _SheetResult.goToRegister:
      context.push(AppRoutes.signup);
    case _SheetResult.recover:
      context.push(AppRoutes.recoverPassword);
    case null:
      break;
  }
}

class _LoginSheetContent extends ConsumerStatefulWidget {
  const _LoginSheetContent();

  @override
  ConsumerState<_LoginSheetContent> createState() => _LoginSheetContentState();
}

class _LoginSheetContentState extends ConsumerState<_LoginSheetContent> {
  bool _showEmail = false;
  bool _googleLoading = false;

  @override
  Widget build(BuildContext context) {
    // El sheet sube con el teclado y respeta el área segura inferior.
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: _dragHandle()),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _showEmail ? _buildEmailView() : _buildOptionsView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dragHandle() => Container(
        margin: const EdgeInsets.only(top: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.gray900.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      );
      
  Widget _logo() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Image.asset('assets/images/logo_tramiapp.png', height: 45),
      );

  // ── Vista de opciones (port de LoginOptionsScreen.kt) ──────────────────────
  Widget _buildOptionsView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _logo()),
        const SizedBox(height: 40),
        // Iniciar sesión (email)
        _primaryPillButton(
          label: 'Iniciar sesión',
          leading: const Icon(Icons.person, color: Colors.white, size: 22),
          onPressed: () => setState(() => _showEmail = true),
        ),
        const SizedBox(height: 20),
        // Continuar con Google
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: _googleLoading ? null : _handleGoogle,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: Colors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: _googleLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset('assets/images/icongoogle.png',
                            width: 22, height: 22),
                      ),
                      const Text(
                        'Continuar con Google',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(child: Text('ó', style: TextStyle(color: Colors.black))),
        const SizedBox(height: 20),
        // Continuar sin una cuenta
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Continuar sin una cuenta',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Registro
        const Center(
          child: Text(
            '¿No tienes una cuenta?',
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        _primaryPillButton(
          label: 'Registrarse',
          onPressed: () {
            // Registro manual: sin borrador de Google.
            ref.read(registrationDraftProvider.notifier).state = null;
            Navigator.of(context).pop(_SheetResult.goToRegister);
          },
        ),
        const SizedBox(height: 20),
        const FooterSponsors(color: AppColors.gray900),
      ],
    );
  }

  // ── Vista de email (port de AuthScreen.kt) ─────────────────────────────────
  Widget _buildEmailView() {
    return _EmailLoginForm(
      onBack: () => setState(() => _showEmail = false),
      logo: _logo(),
    );
  }

  Widget _primaryPillButton({
    required String label,
    Widget? leading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonOptionScreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: leading == null
            ? Text(
                label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  Align(alignment: Alignment.centerLeft, child: leading),
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleGoogle() async {
    setState(() => _googleLoading = true);
    final outcome =
        await ref.read(loginOptionsControllerProvider).signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);

    switch (outcome.status) {
      case GoogleAuthStatus.loggedIn:
        Navigator.of(context).pop(_SheetResult.loggedInWithGoogle);
      case GoogleAuthStatus.goToRegister:
        Navigator.of(context).pop(_SheetResult.goToRegister);
      case GoogleAuthStatus.cancelled:
        break;
      case GoogleAuthStatus.error:
        await _fallbackToRegister();
    }
  }

  /// Puerto de `fallbackToRegister` + el manejo de `NavigateToRegister` con
  /// error del base: avisa, cierra la sesión de Google y, a los 3,2 s, lleva al
  /// registro manual (sin borrador de Google).
  Future<void> _fallbackToRegister() async {
    unawaited(_signOutGoogle());
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: TimedDialog(
          duration: _googleFallbackDelay,
          child: ImportantAlertDialog(
            title: 'Aviso Importante',
            message:
                'No pudimos completar el inicio de sesión con Google. Te llevaremos al registro para que continúes.',
            showProgressBar: true,
            hideDismissButton: true,
            onDismissRequest: () {},
          ),
        ),
      ),
    );
    if (!mounted) return;
    ref.read(registrationDraftProvider.notifier).state = null;
    Navigator.of(context).pop(_SheetResult.goToRegister);
  }

  Future<void> _signOutGoogle() async {
    try {
      await ref.read(googleAuthServiceProvider).signOut();
    } catch (_) {
      // Igual que el base: si falla el cierre, se sigue al registro.
    }
  }
}

/// Formulario de email — vista interna del sheet (campos oscuros `#3D3D4E`).
class _EmailLoginForm extends ConsumerStatefulWidget {
  const _EmailLoginForm({required this.onBack, required this.logo});

  final VoidCallback onBack;
  final Widget logo;

  @override
  ConsumerState<_EmailLoginForm> createState() => _EmailLoginFormState();
}

class _EmailLoginFormState extends ConsumerState<_EmailLoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final res = await ref.read(sessionProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success) {
      Navigator.of(context).pop(_SheetResult.loggedIn);
    } else if (res.invalidInput) {
      // Validación local: el original la muestra bajo el campo.
      setState(() => _errorMessage = res.message);
    } else {
      // Respuesta del backend: `ImportantAlertDialog("No se pudo iniciar
      // sesión", sentencesError)` sobre el sheet, que se borra a los 2 s.
      await showDialog<void>(
        context: context,
        builder: (ctx) => TimedDialog(
          duration: _loginErrorDialogDuration,
          child: ImportantAlertDialog(
            title: 'No se pudo iniciar sesión',
            message: res.message ?? 'No se pudo iniciar sesión.',
            onDismissRequest: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppBackButton(
            onPressed: widget.onBack,
            backgroundColor: AppColors.buttonOptionScreen,
            iconColor: Colors.white,
            tooltip: 'Volver',
          ),
        ),
        Center(child: widget.logo),
        const SizedBox(height: 12),
        _darkField(
          controller: _emailController,
          hint: 'Correo electrónico',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _darkField(
          controller: _passwordController,
          hint: 'Contraseña',
          obscure: _obscure,
          suffix: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.end,
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(_SheetResult.recover),
            child: const Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonOptionScreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Iniciar sesión',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        const FooterSponsors(color: AppColors.gray900),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _darkField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gray400),
        filled: true,
        fillColor: AppColors.authField,
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
