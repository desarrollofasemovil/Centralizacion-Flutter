import 'package:flutter/material.dart';

import 'dialog_typography.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
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
                    // .size(60.dp).border(2.5.dp).padding(5.dp): glifo de 50.
                    child: Container(
                      width: 60,
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.priority_high_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
                if (!hideDismissButton)
                  Align(
                    alignment: Alignment.topRight,
                    // IconButton.size(25.dp).border(1.5.dp).padding(2.dp): el
                    // ícono ocupa los 21 que quedan dentro.
                    child: Semantics(
                      button: true,
                      label: 'Cerrar',
                      child: InkWell(
                        onTap: onDismissRequest,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 25,
                          height: 25,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 21,
                          ),
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
                  textAlign: TextAlign.center,
                  // bodyMedium con fontSize = 18.sp (lineHeight sigue en 16sp).
                  style: DialogTypography.withFontSize(
                    DialogTypography.bodyMedium,
                    18,
                  ).copyWith(color: scheme.onSurface),
                ),
                // AnimatedVisibility(visible = showProgressBar): fade + expand.
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: !showProgressBar
                        ? const SizedBox(width: double.infinity)
                        : Column(
                            key: const ValueKey('progress'),
                            children: [
                              const SizedBox(height: 24),
                              CircularProgressIndicator(color: scheme.primary),
                              const SizedBox(height: 10),
                              Text(
                                'redirigiendo...',
                                style: DialogTypography.bodyMedium.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
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
                      child: Text(
                        confirmButtonText,
                        style: DialogTypography.headlineMedium.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
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
