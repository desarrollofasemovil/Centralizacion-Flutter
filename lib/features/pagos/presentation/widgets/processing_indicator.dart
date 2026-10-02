import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Puerto de `ProcessingIndicator.kt` — iconografía «En proceso» (variante
/// Órbita): un anillo guía estático, tres puntos que orbitan a su alrededor y,
/// al centro, un disco `primaryContainer` con el glifo de una tarjeta.
/// Todo se dibuja con Canvas — sin recursos externos.
class ProcessingIndicator extends StatefulWidget {
  const ProcessingIndicator({super.key, this.size = 120});

  final double size;

  @override
  State<ProcessingIndicator> createState() => _ProcessingIndicatorState();
}

class _ProcessingIndicatorState extends State<ProcessingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _OrbitPainter(
            angleDegrees: _controller.value * 360,
            ringColor: scheme.outlineVariant,
            dotColor: scheme.primary,
            centerColor: scheme.primaryContainer,
            glyphColor: scheme.onPrimaryContainer,
          ),
        );
      },
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.angleDegrees,
    required this.ringColor,
    required this.dotColor,
    required this.centerColor,
    required this.glyphColor,
  });

  final double angleDegrees;
  final Color ringColor;
  final Color dotColor;
  final Color centerColor;
  final Color glyphColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide * 0.45;
    final center = Offset(size.width / 2, size.height / 2);

    // 1 · Anillo guía estático
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 2 · Tres puntos orbitando, con tamaño y opacidad decrecientes
    const dots = [(-90.0, 5.0, 1.00), (30.0, 4.0, 0.55), (150.0, 3.0, 0.30)];
    for (final (deg, dotRadius, alpha) in dots) {
      final rad = (deg + angleDegrees) * math.pi / 180;
      canvas.drawCircle(
        Offset(
          center.dx + radius * math.cos(rad),
          center.dy + radius * math.sin(rad),
        ),
        dotRadius,
        Paint()..color = dotColor.withValues(alpha: alpha),
      );
    }

    // 3 · Disco central + glifo de tarjeta
    canvas.drawCircle(center, radius * 0.64, Paint()..color = centerColor);
    _drawCardGlyph(canvas, center, radius * 0.62);
  }

  /// Glifo de tarjeta de pago: contorno redondeado, banda magnética y chip.
  void _drawCardGlyph(Canvas canvas, Offset center, double width) {
    final height = width * 0.70;
    final topLeft = Offset(center.dx - width / 2, center.dy - height / 2);
    final stroke = width * 0.055;
    final paint = Paint()..color = glyphColor;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        topLeft & Size(width, height),
        Radius.circular(width * 0.13),
      ),
      Paint()
        ..color = glyphColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawRect(
      Offset(topLeft.dx, topLeft.dy + height * 0.26) &
          Size(width, height * 0.16),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset(topLeft.dx + width * 0.15, topLeft.dy + height * 0.64) &
            Size(width * 0.30, height * 0.12),
        Radius.circular(height * 0.06),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.angleDegrees != angleDegrees;
}
