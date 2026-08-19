import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/recovery_password_notifier.dart';

/// Hoja modal para introducir el código de verificación enviado por correo —
/// puerto fiel de `ShowModalVerificationCode.kt`. Se abre cuando
/// `RecoveryPasswordState.showCodeSheet` pasa a `true` y se cierra sola
/// (mediante [Navigator.pop]) en cuanto vuelve a `false` (código incorrecto o
/// verificado con éxito); ver `openVerificationCodeSheet` en
/// `recovery_password_screen.dart` para cómo se distingue ese cierre
/// "manejado" de un cierre por swipe/tap-fuera del usuario.
class VerificationCodeSheet extends ConsumerStatefulWidget {
  const VerificationCodeSheet({super.key, required this.onCancel});

  /// Cancelar: cierra la hoja y abandona todo el flujo (vuelve a login).
  final VoidCallback onCancel;

  @override
  ConsumerState<VerificationCodeSheet> createState() =>
      _VerificationCodeSheetState();
}

class _VerificationCodeSheetState extends ConsumerState<VerificationCodeSheet> {
  bool _popped = false;

  void _popHandled() {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Espejo de `LaunchedEffect(uiState.showCodeSheet) { ... sheetState.hide() }`:
    // cuando el notifier apaga `showCodeSheet` (código incorrecto o
    // verificado), cerramos la hoja nosotros mismos con un resultado
    // "manejado" para que el llamador no lo confunda con un dismiss.
    ref.listen<bool>(
      recoveryPasswordNotifierProvider.select((s) => s.showCodeSheet),
      (prev, next) {
        if (!next) _popHandled();
      },
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 26),
              Text(
                'Introduce el código de verificación.',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: VerificationCodeInput(
                  onCodeComplete: (code) => ref
                      .read(recoveryPasswordNotifierProvider.notifier)
                      .validateCode(code),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gray600, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
              ),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }
}

/// 6 casillas de un dígito con auto-avance de foco — puerto de
/// `VerificationCodeInput.kt`.
class VerificationCodeInput extends StatefulWidget {
  const VerificationCodeInput({super.key, required this.onCodeComplete});

  final ValueChanged<String> onCodeComplete;

  @override
  State<VerificationCodeInput> createState() => _VerificationCodeInputState();
}

class _VerificationCodeInputState extends State<VerificationCodeInput> {
  static const _length = 6;
  late final List<TextEditingController> _controllers =
      List.generate(_length, (_) => TextEditingController());
  late final List<FocusNode> _focusNodes =
      List.generate(_length, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (index == _length - 1 &&
        _controllers.every((c) => c.text.isNotEmpty)) {
      FocusScope.of(context).unfocus();
      widget.onCodeComplete(_controllers.map((c) => c.text).join());
    }
  }

  void _onFocusChanged(int index, bool hasFocus) {
    // Al reenfocar una casilla ya llena, se limpia (igual que el original).
    if (hasFocus && _controllers[index].text.isNotEmpty) {
      _controllers[index].clear();
      setState(() {});
    }
  }

  KeyEventResult _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty) {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Espaciado real ENTRE casillas (equivalente a `Arrangement.spacedBy(10.dp)`
    // del original) en vez de padding dentro de cada celda — así las 6 quedan
    // con el mismo ancho (antes la última, sin padding derecho, salía más
    // ancha que el resto).
    final fields = List.generate(_length, (index) {
      return Expanded(
        child: Focus(
          onKeyEvent: (_, event) => _onKeyEvent(index, event),
          onFocusChange: (has) => _onFocusChanged(index, has),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            onChanged: (v) => _onChanged(index, v),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray600),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray600),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gray900, width: 2),
              ),
            ),
          ),
        ),
      );
    });

    return Row(
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          fields[i],
          if (i < fields.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}
