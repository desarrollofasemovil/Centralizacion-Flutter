import 'package:flutter/material.dart';

/// Diálogo de "campos obligatorios" con cabecera roja e ícono de advertencia.
/// Port fiel de `ui/components/ValidationErrorDialog.kt`.
///
/// Se muestra cuando el usuario intenta continuar sin diligenciar los campos
/// marcados con asterisco (*). Envolver en `showDialog(builder: ...)`.
class ValidationErrorDialog extends StatelessWidget {
  const ValidationErrorDialog({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.colorScheme.surface,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cabecera roja con ícono de advertencia (Color 0xFFEF5350).
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF5350),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Importante",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Los campos marcados con un asterisco (*) son obligatorios.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              tooltip: "Cerrar",
            ),
          ),
        ],
      ),
    );
  }
}
