import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/design.dart';

Color getAdaptiveColor(
  Color backgroundColor,
  Color lightColor,
  Color darkColor,
) {
  return backgroundColor.computeLuminance() > 0.5 ? darkColor : lightColor;
}

class MainHeader extends StatelessWidget {
  final Design design;
  final String? departamento;
  final bool isLoading;

  const MainHeader({
    super.key,
    required this.design,
    this.departamento,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    const contrastColor = Color(0xFF181E31);

    final adaptiveTitleColor = getAdaptiveColor(
      primaryColor,
      Colors.white,
      contrastColor,
    );

    final adaptiveSubtitleColor = getAdaptiveColor(
      primaryColor,
      Colors.white,
      contrastColor,
    );

    if (isLoading) {
      // Esqueleto del header: escudo + líneas de nombre/departamento como shimmer,
      // equivalente a MainHeaderPlaceHolder del original (Compose).
      return Container(
        color: primaryColor,
        width: double.infinity,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            ShimmerPlaceholder(width: 100, height: 100, borderRadius: 12),
            SizedBox(height: 14),
            ShimmerPlaceholder(width: 180, height: 22, borderRadius: 6),
            SizedBox(height: 8),
            ShimmerPlaceholder(width: 120, height: 14, borderRadius: 6),
            SizedBox(height: 15),
          ],
        ),
      );
    }

    return Container(
      color: primaryColor,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: theme.colorScheme.onPrimary,
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(10),
              child: CachedNetworkImage(
                imageUrl: design.escudoUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.location_city,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              design.nombreAlcaldia,
              style: TextStyle(
                color: adaptiveTitleColor,
                fontSize: 25,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (departamento != null && departamento!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                "Departamento de $departamento",
                style: TextStyle(color: adaptiveSubtitleColor, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Barrido de gradiente gris claro (equivalente a Modifier.shimmerLoading del
    // original: LightGray 0.2 → 1.0 → 0.2 desplazándose en diagonal).
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFDFE2E6),
                Color(0xFFF2F4F6),
                Color(0xFFDFE2E6),
              ],
              stops: const [0.1, 0.3, 0.4],
              transform: _SlidingGradientTransform(_controller.value),
            ),
          ),
        );
      },
    );
  }
}

/// Desplaza el gradiente horizontalmente según el progreso [slidePercent] (0→1)
/// para producir el efecto de barrido del shimmer.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2 - 1),
      0,
      0,
    );
  }
}
