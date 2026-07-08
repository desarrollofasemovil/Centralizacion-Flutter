import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/footer_sponsors.dart';

/// Recuperar contraseña — re-estilizado acorde a `RecoveryPasswordScreen.kt`:
/// fondo navy (`primarycolor`), logo centrado, campo blanco redondeado, botones
/// "Cancelar"/"Continuar" y footer de patrocinadores. Conserva la lógica de
/// envío de código (`sendEmailValidationCode`).
class RecoveryPasswordScreen extends ConsumerStatefulWidget {
  const RecoveryPasswordScreen({super.key});

  @override
  ConsumerState<RecoveryPasswordScreen> createState() =>
      _RecoveryPasswordScreenState();
}

class _RecoveryPasswordScreenState extends ConsumerState<RecoveryPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  // Azul del botón "Continuar" del base (0xFF2196F3).
  static const _continueBlue = Color(0xFF2196F3);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) =>
      email.isNotEmpty &&
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email);

  Future<void> _handleRecovery() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Ingresa un correo válido.');
      return;
    }
    setState(() {
      _isLoading = true;
      _successMessage = null;
      _errorMessage = null;
    });
    try {
      final res = await ref
          .read(sendEmailsApiServiceProvider)
          .sendEmailValidationCode(email);
      if (!mounted) return;
      setState(() {
        if (res.booleanStatus) {
          _successMessage = 'Código de verificación enviado. Revisa tu correo.';
        } else {
          _errorMessage = res.sentencesError.isNotEmpty
              ? res.sentencesError
              : 'Error al enviar código de recuperación.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _errorMessage = 'No pudimos conectar con el servidor de correos.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            onPressed: _isLoading ? null : _handleRecovery,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _continueBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Continuar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_successMessage != null)
                    Text(
                      _successMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 40),
                  const FooterSponsors(color: Colors.white),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
