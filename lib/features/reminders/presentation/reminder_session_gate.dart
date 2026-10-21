import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/confirmation_dialog.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/login_bottom_sheet.dart';

/// Hay sesión real para guardar un recordatorio. El invitado (datos sin
/// cuenta, `loginStatus: false`) no cuenta: el backend guarda los
/// recordatorios por usuario.
bool hasReminderSession(WidgetRef ref) =>
    ref.read(sessionProvider)?.loginStatus == true;

/// Antes de crear un recordatorio desde una factura o un pago: sin sesión,
/// explica que se guarda en la cuenta ([message]) y ofrece iniciar sesión.
/// Devuelve `true` si al final hay sesión y se puede seguir al modal.
Future<bool> ensureReminderSession(
  BuildContext context,
  WidgetRef ref, {
  required String message,
}) async {
  if (hasReminderSession(ref)) return true;
  final wantsLogin = await showDialog<bool>(
    context: context,
    builder: (ctx) => ConfirmationDialog(
      title: 'Inicia sesión para recordarte',
      message: message,
      icon: Icons.notifications_active_outlined,
      confirmButtonText: 'Iniciar sesión',
      dismissButtonText: 'Ahora no',
      onConfirm: () => Navigator.of(ctx).pop(true),
      onDismiss: () => Navigator.of(ctx).pop(false),
    ),
  );
  if (wantsLogin != true || !context.mounted) return false;
  await showLoginBottomSheet(context);
  return context.mounted && hasReminderSession(ref);
}
