import 'package:flutter/material.dart';

/// Punto de "notificación" del botón de ayuda.
const _kBadge = Color(0xFFFF5A3C);

/// Globo «¿Necesitas ayuda? Mira un video tutorial» que apunta, a su derecha,
/// al [TutorialHelpButton]. Tocarlo abre el video; la × lo cierra.
class TutorialHelpHint extends StatelessWidget {
  const TutorialHelpHint({
    super.key,
    required this.onPressed,
    required this.onClose,
    required this.background,
    required this.foreground,
  });

  final VoidCallback onPressed;
  final VoidCallback onClose;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    // Con letra muy grande el globo bajaría hasta tapar el «¡Bienvenido!».
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: _bubble(),
    );
  }

  Widget _bubble() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 230),
          child: Material(
            color: background,
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 14, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onClose,
                      tooltip: 'Cerrar aviso',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: foreground.withValues(alpha: 0.6),
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Necesitas ayuda?',
                            style: TextStyle(
                              color: foreground,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Mira un video tutorial',
                            style: TextStyle(color: foreground, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        CustomPaint(
          size: const Size(9, 16),
          painter: _ArrowPainter(background),
        ),
      ],
    );
  }
}

/// Flechita del globo, apuntando a la derecha.
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => oldDelegate.color != color;
}

/// Botón de ayuda: solo el signo `?` (sin círculo); abre el video de cómo pagar.
///
/// Mientras [highlighted], el `?` late (crece y vuelve) y lleva un punto como
/// de notificación, para que lo note quien llega por primera vez. Sin
/// animaciones del sistema (accesibilidad) no late, pero el punto se queda.
class TutorialHelpButton extends StatefulWidget {
  const TutorialHelpButton({
    super.key,
    required this.onPressed,
    required this.color,
    this.highlighted = true,
  });

  final VoidCallback onPressed;

  /// Color del `?` (blanco sobre el fondo de Bienvenida).
  final Color color;
  final bool highlighted;

  @override
  State<TutorialHelpButton> createState() => _TutorialHelpButtonState();
}

class _TutorialHelpButtonState extends State<TutorialHelpButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 1.18,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(TutorialHelpButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final animate =
        widget.highlighted && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!animate && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 56,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: widget.onPressed,
            tooltip: 'Ver tutorial: cómo pagar',
            iconSize: 34,
            color: widget.color,
            constraints: const BoxConstraints.tightFor(width: 56, height: 56),
            icon: ScaleTransition(
              scale: _scale,
              child: const Icon(Icons.question_mark_rounded),
            ),
          ),
          if (widget.highlighted)
            const Positioned(
              key: ValueKey('tutorial-help-badge'),
              top: 10,
              right: 10,
              child: SizedBox.square(
                dimension: 11,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kBadge,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
