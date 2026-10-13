import 'package:flutter/material.dart';

/// Equivalente a `AnimatedContent(targetState = index, transitionSpec = {
/// slideInHorizontally { width } (+ fadeIn()) togetherWith
/// slideOutHorizontally { -width } (+ fadeOut()) })` de Compose.
///
/// Si [index] sube, el contenido nuevo entra por la derecha y el viejo sale
/// por la izquierda; si baja, al revés. [fade] añade el `fadeIn()/fadeOut()`.
class SlideSwitcher extends StatefulWidget {
  const SlideSwitcher({
    super.key,
    required this.index,
    required this.child,
    this.fade = true,
    this.duration = const Duration(milliseconds: 300),
  });

  final int index;
  final Widget child;
  final bool fade;
  final Duration duration;

  @override
  State<SlideSwitcher> createState() => _SlideSwitcherState();
}

class _SlideSwitcherState extends State<SlideSwitcher> {
  int _direction = 1;

  @override
  void didUpdateWidget(SlideSwitcher old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index) {
      _direction = widget.index > old.index ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentKey = ValueKey<int>(widget.index);
    return ClipRect(
      child: AnimatedSize(
        duration: widget.duration,
        curve: Curves.fastOutSlowIn,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: widget.duration,
          switchInCurve: Curves.fastOutSlowIn,
          switchOutCurve: Curves.fastOutSlowIn,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            fit: StackFit.passthrough,
            children: [...previous, ?current],
          ),
          transitionBuilder: (child, animation) {
            // El que entra va 0→1; el que sale corre en reversa 1→0.
            final incoming = child.key == currentKey;
            final sign = incoming ? _direction : -_direction;
            Widget result = AnimatedBuilder(
              animation: animation,
              builder: (context, c) => FractionalTranslation(
                translation: Offset(sign * (1 - animation.value), 0),
                child: c,
              ),
              child: child,
            );
            if (widget.fade) {
              result = FadeTransition(opacity: animation, child: result);
            }
            return result;
          },
          child: KeyedSubtree(key: currentKey, child: widget.child),
        ),
      ),
    );
  }
}
