import 'package:flutter/material.dart';
import '../../../tramites/domain/info_tramite.dart';
import 'main_header.dart'; // For ShimmerPlaceholder

class TramiteCard extends StatelessWidget {
  final InfoTramite cardinfo;
  final VoidCallback onClick;

  const TramiteCard({
    super.key,
    required this.cardinfo,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Si el fondo es blanco (como en redes sociales), tintamos el ícono del color primario.
    // Si el fondo es pastel, tintamos el ícono del color de contraste (navy oscuro) o primario para visibilidad.
    final iconColor = cardinfo.color == Colors.white 
        ? theme.colorScheme.primary 
        : const Color(0xFF181E31);

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
              child: Icon(
                cardinfo.icono,
                color: iconColor,
                size: 36,
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
          ShimmerPlaceholder(
            width: 80,
            height: 16,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}
