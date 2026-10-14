import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/review/review_prompt_service.dart';
import '../../../core/widgets/dialog_typography.dart';

/// Diálogos de resultado de una radicación PQRD. Port de
/// `SuccessPqrdDialog.kt` y `ErrorPqrdDialog.kt`.
///
/// El original usa el `AlertDialog` de Material 3 (no los diálogos de marca
/// `ConfirmationDialog`/`ImportantAlertDialog`), así que aquí también: está en
/// la lista de excepciones de `test/core/dialog_parity_test.dart`.
///
/// Ambos se cierran también tocando fuera (`onDismissRequest = onDismiss`):
/// [onDismiss] corre sea cual sea la forma de cerrarlo.

Future<void> showPqrdSuccessDialog(
  BuildContext context,
  String ticket, {
  VoidCallback? onDismiss,
}) async {
  // Se toma antes: `onDismiss` navega y puede desmontar `context`.
  final review =
      ProviderScope.containerOf(context, listen: false)
          .read(reviewPromptServiceProvider);
  await showDialog<void>(
    context: context,
    builder: (ctx) => _PqrdResultDialog(
      title: '¡Éxito!',
      message:
          'Tu solicitud ha sido enviada correctamente. Tu número de ticket es: $ticket',
    ),
  );
  onDismiss?.call();
  // Reseña de la tienda tras ver el radicado (FSM-59).
  unawaited(review.onPositiveMoment(ReviewTrigger.pqrdFiled));
}

Future<void> showPqrdErrorDialog(
  BuildContext context,
  String message, {
  VoidCallback? onDismiss,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _PqrdResultDialog(title: 'Error', message: message),
  );
  onDismiss?.call();
}

class _PqrdResultDialog extends StatelessWidget {
  const _PqrdResultDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Estilos por defecto de un `AlertDialog` M3 de Compose con el `Type.kt`
    // de la app: título = headlineSmall, texto = bodyMedium.
    return AlertDialog(
      title: Text(title),
      titleTextStyle: DialogTypography.headlineSmall.copyWith(
        color: scheme.onSurface,
      ),
      content: Text(message),
      contentTextStyle: DialogTypography.bodyMedium.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
