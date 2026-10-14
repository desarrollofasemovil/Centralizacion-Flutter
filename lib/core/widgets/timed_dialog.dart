import 'dart:async';

import 'package:flutter/widgets.dart';

/// Cierra el diálogo que lo contiene cuando pasa [duration], tras ejecutar
/// [onElapsed] (si se da).
///
/// Es el `LaunchedEffect(flag) { delay(x); flag = false }` con el que el
/// original cierra solos varios diálogos: "Inicio de sesión exitoso" (2 s en
/// Home, 1,5 s en Configuración), "No se pudo iniciar sesión" (2 s), el aviso de
/// sitio externo (3 s, abre la URL y se cierra) y el aviso de Google (3,2 s).
///
/// El timer vive en el `State` del diálogo: si el diálogo se cierra antes (toque
/// fuera, X, la pantalla se desmonta), se cancela y [onElapsed] no corre.
class TimedDialog extends StatefulWidget {
  const TimedDialog({
    super.key,
    required this.duration,
    required this.child,
    this.onElapsed,
  });

  final Duration duration;
  final Widget child;

  /// Se ejecuta justo antes de cerrar el diálogo. No se espera: igual que el
  /// original, que lanza `abrirURL(...)` y en el mismo frame oculta el diálogo.
  final VoidCallback? onElapsed;

  @override
  State<TimedDialog> createState() => _TimedDialogState();
}

class _TimedDialogState extends State<TimedDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _elapsed);
  }

  void _elapsed() {
    if (!mounted) return;
    widget.onElapsed?.call();
    // Cierra SU ruta, no "lo que esté arriba": si algo se apiló encima, un
    // `pop()` a ciegas cerraría lo equivocado.
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    final navigator = Navigator.of(context);
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
