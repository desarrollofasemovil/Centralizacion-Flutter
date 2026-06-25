import 'package:flutter/material.dart';

/// Campo de fecha — puerto de `DatePickerField`: caja clickable de alto fijo
/// (52, `inputFieldHeight`), borde `medium`, que muestra el valor o el label y
/// abre un selector de fecha al tocarse.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.value,
    required this.label,
    required this.onTap,
    this.errorText,
  });

  final String value;
  final String label;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value.trim().isNotEmpty;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError ? scheme.error : scheme.outline,
              ),
            ),
            child: Text(
              hasValue ? value : label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: hasValue ? scheme.onSurface : scheme.outline,
                  ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              errorText!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}
