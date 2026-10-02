import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../tramites/domain/info_tramite.dart';
import 'main_header.dart'; // For ShimmerPlaceholder

class TramiteCard extends StatelessWidget {
  final InfoTramite cardinfo;
  final VoidCallback onClick;

  const TramiteCard({super.key, required this.cardinfo, required this.onClick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cardinfo.color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              // El SVG conserva sus colores propios (igual que `tint = Unspecified`
              // en el original); no se aplica colorFilter.
              child: SvgPicture.asset(
                cardinfo.icono,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              cardinfo.nombre,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                height: 1.0,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class TramiteCardPlaceholder extends StatelessWidget {
  const TramiteCardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShimmerPlaceholder(
            width: 72,
            height: 72,
            borderRadius: 36, // Circular shape
          ),
          SizedBox(height: 10),
          ShimmerPlaceholder(width: 80, height: 16, borderRadius: 4),
        ],
      ),
    );
  }
}
