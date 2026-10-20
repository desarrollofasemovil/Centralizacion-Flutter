import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reminders_notifier.dart';

/// Muestra en un `SnackBar` los avisos de Recordatorios ("programado con
/// éxito", "eliminado", errores de permisos…) en la pantalla que lo envuelve.
///
/// Antes este listener vivía solo dentro de la sección de la Home, así que un
/// recordatorio creado desde otra pantalla (p. ej. "Recordarme" en una
/// factura) dependía de que la Home siguiera montada debajo para verse.
///
/// Si hay varias pantallas envueltas en la pila, solo avisa la que está al
/// frente: las que quedan tapadas por una ruta opaca tienen el `TickerMode`
/// apagado. Un bottom sheet no es opaco, así que la pantalla de debajo sigue
/// avisando mientras el modal de creación está abierto.
class ReminderToastListener extends ConsumerWidget {
  const ReminderToastListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnTop = TickerMode.valuesOf(context).enabled;
    ref.listen<String?>(
      remindersNotifierProvider.select((s) => s.toastMessage),
      (_, next) {
        if (!isOnTop || next == null || next.isEmpty) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next)));
        ref.read(remindersNotifierProvider.notifier).consumeToast();
      },
    );
    return child;
  }
}
