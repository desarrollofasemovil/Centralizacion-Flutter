import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/widgets/important_alert_dialog.dart';
import '../../../../core/widgets/timed_dialog.dart';
import '../../application/main_viewmodel.dart';

/// Espera del aviso antes de abrir la URL (`delay(3000L)` en `MainScreen.kt`).
const externalLinkRedirectDelay = Duration(seconds: 3);

/// Abre [pending] con [opener]: directo, o tras el aviso de sitio externo si
/// [PendingUrl.showWarning] — puerto del manejo de `MainEvent.OpenUrl` en
/// `MainScreen.kt` (`showExternalLinkDialog` + su `LaunchedEffect`).
void openPendingUrl(
  BuildContext context,
  PendingUrl pending, {
  required Future<bool> Function(String url) opener,
}) {
  if (!pending.showWarning) {
    unawaited(opener(pending.url));
    return;
  }
  unawaited(
    showDialog<void>(
      context: context,
      // No se puede cerrar mientras redirige: sin X, sin toque fuera y sin
      // Atrás (el `PopScope` de abajo).
      barrierDismissible: false,
      builder: (_) =>
          ExternalLinkWarningDialog(onRedirect: () => opener(pending.url)),
    ),
  );
}

/// "Aviso Importante — Estás a punto de ser redirigido…" con "redirigiendo...".
/// A los [externalLinkRedirectDelay] llama [onRedirect] y se cierra solo.
class ExternalLinkWarningDialog extends StatelessWidget {
  const ExternalLinkWarningDialog({super.key, required this.onRedirect});

  final VoidCallback onRedirect;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: TimedDialog(
        duration: externalLinkRedirectDelay,
        onElapsed: onRedirect,
        child: ImportantAlertDialog(
          title: 'Aviso Importante',
          message:
              'Estás a punto de ser redirigido a un sitio web externo a nuestra aplicación.',
          showProgressBar: true,
          hideDismissButton: true,
          onDismissRequest: () {},
        ),
      ),
    );
  }
}
