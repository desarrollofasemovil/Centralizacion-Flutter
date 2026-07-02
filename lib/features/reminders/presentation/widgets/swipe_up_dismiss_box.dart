import 'package:flutter/material.dart';

/// Caja que se descarta deslizando hacia arriba. Port de
/// `ui/components/SwipeUpDismissBox.kt`.
///
/// Durante el arrastre sigue el dedo y se hace semitransparente; al soltar, si
/// superó el umbral, sale volando hacia arriba y dispara [onDismiss]; si no,
/// rebota a su posición. Funciona igual en iOS y Android (gestos verticales).
class SwipeUpDismissBox extends StatefulWidget {
  const SwipeUpDismissBox({
    super.key,
    required this.onDismiss,
    required this.child,
  });

  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<SwipeUpDismissBox> createState() => _SwipeUpDismissBoxState();
}

class _SwipeUpDismissBoxState extends State<SwipeUpDismissBox>
    with SingleTickerProviderStateMixin {
  static const double _dismissThreshold = -320;

  double _offsetY = 0;
  double _opacity = 1;

  late final AnimationController _controller;
  Animation<double>? _offsetAnim;
  Animation<double>? _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        setState(() {
          _offsetY = _offsetAnim?.value ?? _offsetY;
          _opacity = _opacityAnim?.value ?? _opacity;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final next = _offsetY + details.delta.dy;
    if (next <= 0) {
      final progress = (next / _dismissThreshold).clamp(0.0, 1.0);
      setState(() {
        _offsetY = next;
        _opacity = 1 - (progress * 0.6);
      });
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_offsetY < _dismissThreshold) {
      _animate(fromOffset: _offsetY, toOffset: -1000, toOpacity: 0, then: () {
        widget.onDismiss();
        setState(() {
          _offsetY = 0;
          _opacity = 1;
        });
      });
    } else {
      _animate(fromOffset: _offsetY, toOffset: 0, toOpacity: 1);
    }
  }

  void _animate({
    required double fromOffset,
    required double toOffset,
    required double toOpacity,
    VoidCallback? then,
  }) {
    _offsetAnim = Tween<double>(begin: fromOffset, end: toOffset)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnim = Tween<double>(begin: _opacity, end: toOpacity)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller
      ..reset()
      ..forward().whenComplete(() => then?.call());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Opacity(
        opacity: _opacity,
        child: Transform.translate(
          offset: Offset(0, _offsetY),
          child: widget.child,
        ),
      ),
    );
  }
}
