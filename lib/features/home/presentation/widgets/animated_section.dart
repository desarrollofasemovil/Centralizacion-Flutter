import 'dart:async';

import 'package:flutter/material.dart';

/// Animación de entrada de cada sección de la Home: aparece con un desvanecido
/// (alpha 0→1) y un ligero deslizamiento hacia arriba (translationY 10→0) en
/// 500 ms, con un retardo opcional para escalonar las secciones.
/// Equivalente a `AnimatedSection` del original (Compose).
class AnimatedSection extends StatefulWidget {
  final Widget child;
  final int delayMillis;

  const AnimatedSection({super.key, required this.child, this.delayMillis = 0});

  @override
  State<AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<AnimatedSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
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
        final t = Curves.fastOutSlowIn.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 24),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
