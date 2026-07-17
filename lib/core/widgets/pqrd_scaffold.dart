import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Cabecera + cuerpo de las pantallas PQRD. Port de `ui/components/TopbarNavigation.kt`
/// (un `LargeTopAppBar` de Compose con `enterAlwaysScrollBehavior`): franja con el
/// color primario del municipio, botón de retroceso en círculo blanco, insignia
/// circular blanca con el ícono del trámite, título y descripción; el cuerpo va
/// en un contenedor con esquinas superiores redondeadas sobre la franja.
///
/// **Colapsa al hacer scroll**, igual que el original: al desplazarse la insignia
/// se reacomoda y encoge, la descripción se desvanece y solo queda el título en
/// una sola fila. Implementado con un [SliverPersistentHeader] `pinned` cuyo
/// delegate hace un crossfade entre el estado expandido y el colapsado (robusto
/// para títulos de una o dos líneas). El [body] NO debe traer su propio scroll:
/// se desplaza junto con la cabecera dentro del [CustomScrollView].
class PqrdScaffold extends StatelessWidget {
  const PqrdScaffold({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.description,
    required this.body,
    this.onBack,
  });

  /// Ruta del asset SVG del ícono del trámite (se tinta con el color primario).
  final String iconAsset;
  final String title;
  final String description;
  final Widget body;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;

    final delegate = _PqrdHeaderDelegate(
      iconAsset: iconAsset,
      title: title,
      description: description,
      onBack: onBack ?? () => Navigator.of(context).maybePop(),
      topInset: topInset,
      primary: scheme.primary,
      onPrimary: scheme.onPrimary,
      textTheme: theme.textTheme,
    );

    return Scaffold(
      backgroundColor: scheme.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          return CustomScrollView(
            slivers: [
              SliverPersistentHeader(pinned: true, delegate: delegate),
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  // Garantiza que el cuerpo blanco llegue al fondo aunque el
                  // contenido sea corto, y deja margen de scroll para colapsar.
                  constraints: BoxConstraints(
                    minHeight: (viewportHeight - delegate.minExtent)
                        .clamp(0.0, double.infinity),
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: body,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PqrdHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PqrdHeaderDelegate({
    required this.iconAsset,
    required this.title,
    required this.description,
    required this.onBack,
    required this.topInset,
    required this.primary,
    required this.onPrimary,
    required this.textTheme,
  });

  final String iconAsset;
  final String title;
  final String description;
  final VoidCallback onBack;
  final double topInset;
  final Color primary;
  final Color onPrimary;
  final TextTheme textTheme;

  // Alto de la barra colapsada (bajo el status bar) y alto extra en expandido.
  static const double _toolbar = 56;
  static const double _expandedExtra = 92;

  @override
  double get minExtent => topInset + _toolbar;

  @override
  double get maxExtent => topInset + _toolbar + _expandedExtra;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    // 0 = expandido, 1 = colapsado. Crossfade con umbral en 0.5.
    final expandedOpacity = (1 - t / 0.5).clamp(0.0, 1.0);
    final collapsedOpacity = ((t - 0.5) / 0.5).clamp(0.0, 1.0);

    return ClipRect(
      child: Container(
        color: primary,
        child: Stack(
          children: [
            // ---- Contenido expandido: insignia + título + descripción ----
            Positioned(
              left: 16,
              right: 16,
              top: topInset + 52,
              child: IgnorePointer(
                ignoring: expandedOpacity < 0.5,
                child: Opacity(
                  opacity: expandedOpacity,
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          iconAsset,
                          colorFilter:
                              ColorFilter.mode(primary, BlendMode.srcIn),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleLarge?.copyWith(
                                color: onPrimary,
                                fontWeight: FontWeight.bold,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: onPrimary.withValues(alpha: 0.92),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ---- Contenido colapsado: ícono pequeño + solo título ----
            Positioned(
              left: 64,
              right: 16,
              top: topInset,
              height: _toolbar,
              child: IgnorePointer(
                ignoring: collapsedOpacity < 0.5,
                child: Opacity(
                  opacity: collapsedOpacity,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: SvgPicture.asset(
                            iconAsset,
                            colorFilter:
                                ColorFilter.mode(onPrimary, BlendMode.srcIn),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ---- Botón de retroceso (siempre visible, fijo) ----
            Positioned(
              left: 16,
              top: topInset + (_toolbar - 40) / 2,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBack,
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PqrdHeaderDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.description != description ||
        oldDelegate.iconAsset != iconAsset ||
        oldDelegate.topInset != topInset ||
        oldDelegate.primary != primary ||
        oldDelegate.onPrimary != onPrimary;
  }
}
