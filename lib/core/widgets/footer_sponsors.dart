import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Pie con los logos de patrocinadores. Port de `FooterSponsors.kt`:
/// `fadeIn(tween(400, delay 100)) + scaleIn(tween(400, delay 100)) +
/// slideInVertically(tween(400, delay 400), initialOffsetY = -fullHeight)`.
class FooterSponsors extends StatefulWidget {
  const FooterSponsors({super.key, required this.color});

  final Color color;

  @override
  State<FooterSponsors> createState() => _FooterSponsorsState();
}

class _FooterSponsorsState extends State<FooterSponsors>
    with SingleTickerProviderStateMixin {
  // Fade y scale: 100–500 ms. Slide: 400–800 ms.
  static const _totalMs = 800.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  late final Animation<double> _fadeScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      100 / _totalMs,
      500 / _totalMs,
      curve: Curves.fastOutSlowIn,
    ),
  );
  late final Animation<double> _slide = CurvedAnimation(
    parent: _controller,
    curve: const Interval(400 / _totalMs, 1, curve: Curves.fastOutSlowIn),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final tint = ColorFilter.mode(color, BlendMode.srcIn);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fadeScale.value,
        child: FractionalTranslation(
          translation: Offset(0, -(1 - _slide.value)),
          child: Transform.scale(scale: _fadeScale.value, child: child),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/icobancolombia.svg',
            height: 16,
            colorFilter: tint,
          ),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: color.withValues(alpha: 0.5),
          ),
          SvgPicture.asset(
            'assets/images/ico101software.svg',
            height: 20,
            colorFilter: tint,
          ),
        ],
      ),
    );
  }
}
