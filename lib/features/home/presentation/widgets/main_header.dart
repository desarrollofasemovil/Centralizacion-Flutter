import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/design.dart';

Color getAdaptiveColor(Color backgroundColor, Color lightColor, Color darkColor) {
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
      return Container(
        color: primaryColor,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            const ShimmerPlaceholder(
              width: 100,
              height: 100,
              borderRadius: 12,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(height: 5),
            if (departamento != null && departamento!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  departamento!,
                  style: TextStyle(
                    color: adaptiveSubtitleColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 15),
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
                style: TextStyle(
                  color: adaptiveSubtitleColor,
                  fontSize: 14,
                ),
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
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.4),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}
