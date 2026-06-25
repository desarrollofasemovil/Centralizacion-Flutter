import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_providers.dart';
import '../application/login_options_controller.dart';
import '../application/registration_draft.dart';
import 'widgets/footer_sponsors.dart';

/// Resultado con el que se cierra el sheet, para que el llamador navegue/avise
/// usando el contexto de la página (no el del sheet, que ya no existe tras pop).
enum _SheetResult { loggedIn, goToRegister, recover }

/// Muestra el ModalBottomSheet de login (opciones + email) — puerto del
/// `ModalBottomSheet` que el base hospeda en `MainScreen.kt` (color `Gray300`).
Future<void> showLoginBottomSheet(BuildContext context) async {
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
    case _SheetResult.loggedIn:
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(Icons.check_circle,
              color: Theme.of(ctx).colorScheme.primary, size: 48),
          title: const Text('Inicio de sesión exitoso'),
          content: const Text('Has iniciado sesión correctamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _showEmail ? _buildEmailView() : _buildOptionsView(),
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
        Navigator.of(context).pop(_SheetResult.loggedIn);
      case GoogleAuthStatus.goToRegister:
        Navigator.of(context).pop(_SheetResult.goToRegister);
      case GoogleAuthStatus.cancelled:
        break;
      case GoogleAuthStatus.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(outcome.message ?? 'Error con Google.')),
        );
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
    } else {
      setState(() => _errorMessage = res.message ?? 'No se pudo iniciar sesión.');
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
          child: IconButton(
            onPressed: widget.onBack,
            icon: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.buttonOptionScreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
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
