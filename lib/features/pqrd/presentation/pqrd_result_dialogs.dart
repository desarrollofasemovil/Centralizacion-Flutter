import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/review/review_prompt_service.dart';

/// Diálogos de resultado de una radicación PQRD. Port de
/// `SuccessPqrdDialog.kt` y `ErrorPqrdDialog.kt`.

Future<void> showPqrdSuccessDialog(
  BuildContext context,
  String ticket, {
  VoidCallback? onDismiss,
}) {
  // Se toma antes: `onDismiss` navega y puede desmontar `context`.
  final review =
      ProviderScope.containerOf(context, listen: false)
          .read(reviewPromptServiceProvider);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('¡Éxito!'),
      content: Text(
        'Tu solicitud ha sido enviada correctamente.\n'
        'Tu número de ticket es: $ticket',
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            onDismiss?.call();
            // Reseña de la tienda tras ver el radicado (FSM-59).
            unawaited(review.onPositiveMoment(ReviewTrigger.pqrdFiled));
          },
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}

Future<void> showPqrdErrorDialog(
  BuildContext context,
  String message, {
  VoidCallback? onDismiss,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Error'),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            onDismiss?.call();
          },
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}
