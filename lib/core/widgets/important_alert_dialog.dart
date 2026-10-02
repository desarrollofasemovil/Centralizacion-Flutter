import 'package:flutter/material.dart';

const _redColor = Color(0xFFE53935);

/// Puerto de `ui/components/ImportantAlertDialog.kt`: diálogo con cabecera
/// roja, ícono de alerta en círculo, botón de cierre opcional y botón de
/// confirmación opcional.
class ImportantAlertDialog extends StatelessWidget {
  const ImportantAlertDialog({
    super.key,
    required this.onDismissRequest,
    this.onConfirmRequest,
    this.title = 'Importante',
    this.message = 'Los campos marcados con un asterisco (*) son obligatorios.',
    this.confirmButtonText = 'Aceptar',
    this.showProgressBar = false,
    this.hideDismissButton = false,
  });

  final VoidCallback onDismissRequest;
  final VoidCallback? onConfirmRequest;
  final String title;
  final String message;
  final String confirmButtonText;
  final bool showProgressBar;
  final bool hideDismissButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: scheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabecera roja con ícono de alerta y botón de cierre
          Container(
            width: double.infinity,
            color: _redColor,
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 20,
              left: 12,
              right: 12,
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.priority_high_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                if (!hideDismissButton)
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: onDismissRequest,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18),
                ),
                if (showProgressBar) ...[
                  const SizedBox(height: 24),
                  CircularProgressIndicator(color: scheme.primary),
                  const SizedBox(height: 10),
                  Text('redirigiendo...', style: theme.textTheme.bodyMedium),
                ],
                if (onConfirmRequest != null) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton(
                      onPressed: onConfirmRequest,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        side: BorderSide(color: scheme.onSurface),
                        foregroundColor: scheme.onSurface,
                      ),
                      child: Text(confirmButtonText),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
