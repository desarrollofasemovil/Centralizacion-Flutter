import 'dart:async';

import 'package:flutter/material.dart';

/// Equivalente a `AnimatedVisibility(enter = fadeIn(tween(...)) +
/// slideInVertically(...))` de Compose, para el caso "aparece al montarse".
///
/// - [offsetDp]: desplazamiento inicial en dp (negativo = viene de arriba,
///   `slideInVertically(initialOffsetY = { -50 })`).
/// - [offsetFactor]: desplazamiento inicial como fracción de la altura propia
///   (`initialOffsetY = { fullHeight -> fullHeight }` → 1.0). Se suma a
///   [offsetDp].
/// - [fadeMillis]: duración del `fadeIn(tween(n))`.
/// - [slideMillis]: duración del slide. El `slideInVertically` por defecto es
///   un spring que asienta en ~500 ms; con `tween(500, delay)` explícito se
///   pasa el mismo valor que el fade.
/// - [delayMillis]: `delayMillis` del `tween` (aplica a fade y slide).
class EnterTransition extends StatefulWidget {
  const EnterTransition({
    super.key,
    required this.child,
    this.offsetDp = 0,
    this.offsetFactor = 0,
    this.fadeMillis = 500,
    this.slideMillis = 500,
    this.delayMillis = 0,
  });

  final Widget child;
  final double offsetDp;
  final double offsetFactor;
  final int fadeMillis;
  final int slideMillis;
  final int delayMillis;

  @override
  State<EnterTransition> createState() => _EnterTransitionState();
}

class _EnterTransitionState extends State<EnterTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _slide;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    final total = widget.fadeMillis > widget.slideMillis
        ? widget.fadeMillis
        : widget.slideMillis;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Interval(0, widget.fadeMillis / total, curve: Curves.easeOut),
    );
    _slide = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        0,
        widget.slideMillis / total,
        curve: Curves.fastOutSlowIn,
      ),
    );
    // `visible` pasa a true tras el primer frame (LaunchedEffect en Kotlin).
    _startTimer = Timer(Duration(milliseconds: widget.delayMillis), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final remaining = 1 - _slide.value;
        return Opacity(
          opacity: _fade.value,
          child: widget.offsetFactor == 0
              ? Transform.translate(
                  offset: Offset(0, widget.offsetDp * remaining),
                  child: child,
                )
              : FractionalTranslation(
                  translation: Offset(0, widget.offsetFactor * remaining),
                  child: Transform.translate(
                    offset: Offset(0, widget.offsetDp * remaining),
                    child: child,
                  ),
                ),
        );
      },
      child: widget.child,
    );
  }
}
