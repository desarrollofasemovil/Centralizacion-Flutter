import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'dialog_typography.dart';

/// Campo de texto de los formularios con el estilo de Certificados (el
/// `OutlinedTextField` / `outLineTextColor` del original): esquinas 10, borde
/// [AppColors.gray400] en reposo y primario al enfocar, etiqueta `bodyMedium`
/// y fondo `surfaceContainerLowest`.
///
/// Mantiene su propio controlador y lo sincroniza con [value], para que el
/// notifier pueda cambiar el texto (autollenado de la sesión) sin que el campo
/// pierda el cursor mientras se escribe.
///
/// [hasSupportingText] reserva el renglón del texto de apoyo (como Compose),
/// que es el aire entre campos: así un mensaje de [error] no los desplaza.
class OutlinedFormField extends StatefulWidget {
  const OutlinedFormField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.error,
    this.hasSupportingText = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final String? error;
  final bool hasSupportingText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<OutlinedFormField> createState() => _OutlinedFormFieldState();
}

class _OutlinedFormFieldState extends State<OutlinedFormField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant OutlinedFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = _controller.value.copyWith(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      style: DialogTypography.bodyMedium.copyWith(color: scheme.onSurface),
      maxLines: 1,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: DialogTypography.bodyMedium.copyWith(
          color: AppColors.gray400,
        ),
        floatingLabelStyle: DialogTypography.bodyMedium.copyWith(
          color: widget.error != null ? scheme.error : scheme.primary,
        ),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(AppColors.gray400),
        enabledBorder: border(AppColors.gray400),
        focusedBorder: border(scheme.primary, 2),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 2),
        errorText: widget.error,
        errorStyle: DialogTypography.bodySmall.copyWith(color: scheme.error),
        helperText: widget.hasSupportingText ? ' ' : null,
        helperStyle: DialogTypography.bodySmall,
      ),
    );
  }
}
