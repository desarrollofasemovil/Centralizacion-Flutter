import 'package:flutter/material.dart';

import 'dialog_typography.dart';

/// Diálogo de confirmación con cabecera de color de marca e ícono circular.
/// Port de `ui/components/ConfirmationDialog.kt`.
///
/// Si [confirmButtonText] y [dismissButtonText] son ambos `null`, el original
/// no pinta botones: el diálogo se cierra tocando fuera (o solo, si el llamador
/// lo envuelve en un `TimedDialog`, como "Inicio de sesión exitoso").
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onDismiss,
    this.icon = Icons.help_outline,
    this.confirmButtonText,
    this.dismissButtonText,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  final IconData icon;
  final String? confirmButtonText;
  final String? dismissButtonText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final buttonText = DialogTypography.headlineSmall;
    return Dialog(
      // Card(RoundedCornerShape(16.dp), containerColor = surface).
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera de color dinámico (municipio).
          Container(
            padding: const EdgeInsets.symmetric(vertical: 25),
            color: scheme.primary,
            alignment: Alignment.center,
            // Icon(...).size(60.dp).border(2.5.dp, White, CircleShape)
            // .padding(5.dp): caja de 60 con el borde encima y el glifo de 50.
            child: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: Icon(icon, color: Colors.white, size: 50),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            // `horizontalAlignment = CenterHorizontally`: un mensaje de una
            // línea queda centrado; uno largo ocupa el ancho y se alinea al
            // inicio (`TextAlign.Start`).
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: DialogTypography.titleLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.start,
                  // bodyMedium con fontSize 16.sp y lineHeight 20.sp.
                  style: DialogTypography.bodyMedium.copyWith(
                    height: 20 / 16,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                // `OverflowBar` y no `Row`: en un teléfono de 360 dp dos textos
                // de botón algo largos ("Iniciar sesión" + "Ahora no") no caben
                // en una fila y el `Row` se desbordaba. Si caben se ven igual
                // que antes; si no, se apilan alineados al final.
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowAlignment: OverflowBarAlignment.end,
                  spacing: 8,
                  overflowSpacing: 4,
                  children: [
                    if (dismissButtonText != null)
                      TextButton(
                        onPressed: onDismiss,
                        child: Text(
                          dismissButtonText!,
                          style: buttonText.copyWith(color: scheme.onSurface),
                        ),
                      ),
                    if (confirmButtonText != null)
                      // `Button` de M3 = botón relleno sin elevación.
                      FilledButton(
                        onPressed: onConfirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                        ),
                        child: Text(
                          confirmButtonText!,
                          style: buttonText.copyWith(color: scheme.onPrimary),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
