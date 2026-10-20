import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/theme/design.dart';
import '../../../../core/widgets/app_back_button.dart';
import 'main_header.dart';

/// Cabecera colapsable de la Home (barra superior + escudo, nombre de la
/// alcaldía y departamento), con el mismo comportamiento que la de Historial
/// de pagos ([TopBarNavigationScaffold]): va dentro del scroll como un
/// `SliverPersistentHeader` `pinned`.
///
/// * **Desplegada:** botones atrás y menú arriba y, debajo, el escudo grande
///   centrado con el nombre y el departamento.
/// * **Recogida:** no queda en una sola franja. Conserva la fila de botones y,
///   debajo, el escudo a la izquierda con el nombre y el departamento a su lado:
///   la misma disposición que Historial de pagos tiene desplegada.
///
/// El escudo se desplaza y se encoge de forma continua con el scroll; los textos
/// hacen un crossfade con umbral en 0.5 (como Historial).
class MainHeaderDelegate extends SliverPersistentHeaderDelegate {
  MainHeaderDelegate._({
    required this.design,
    required this.departamento,
    required this.isLoading,
    required this.onMenu,
    required this.onBack,
    required this.topInset,
    required this.width,
    required this.nameHeight,
    required this.departmentHeight,
  });

  /// Mide el nombre y el departamento con el estilo y el escalado de texto
  /// reales para fijar el alto de la cabecera desplegada (un nombre largo puede
  /// ocupar dos líneas).
  factory MainHeaderDelegate.measured(
    BuildContext context, {
    required Design design,
    required String? departamento,
    required bool isLoading,
    required VoidCallback onMenu,
    required VoidCallback onBack,
    required double topInset,
    required double width,
  }) {
    final textWidth = width - 2 * _expandedTextInset;
    final department = _departmentLabel(departamento);
    return MainHeaderDelegate._(
      design: design,
      departamento: departamento,
      isLoading: isLoading,
      onMenu: onMenu,
      onBack: onBack,
      topInset: topInset,
      width: width,
      nameHeight: _measure(
        context,
        design.nombreAlcaldia,
        _expandedNameStyle,
        maxLines: 2,
        maxWidth: textWidth,
      ),
      departmentHeight: department == null
          ? 0
          : _measure(
              context,
              department,
              _expandedDepartmentStyle,
              maxLines: 1,
              maxWidth: textWidth,
            ),
    );
  }

  final Design design;
  final String? departamento;
  final bool isLoading;
  final VoidCallback onMenu;
  final VoidCallback onBack;
  final double topInset;
  final double width;
  final double nameHeight;
  final double departmentHeight;

  /// Claves para los tests: la capa visible en cada estado.
  static const expandedKey = Key('main-header-expanded');
  static const collapsedKey = Key('main-header-collapsed');

  static const double _toolbar = AppBackButton.barHeight;
  static const double _shieldBig = 100;
  static const double _expandedTextInset = 16;
  static const double _menuSize = 38;
  static const double _menuInset = 15;

  // Disposición recogida = la de Historial de pagos desplegada
  // (`TopBarNavigationScaffold`): fila de 64 bajo la barra, con 92 de alto extra.
  static const double _rowShield = 64;
  static const double _rowGap = 14;
  static const double _rowInset = 16;
  static const double _rowOffset = -4;
  static const double _collapsedExtra = 92;

  static const _expandedNameStyle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w500,
  );
  static const _expandedDepartmentStyle = TextStyle(fontSize: 14);
  static const _collapsedNameStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.05,
  );
  static const _collapsedDepartmentStyle = TextStyle(fontSize: 13, height: 1.2);

  static String? _departmentLabel(String? departamento) =>
      departamento == null || departamento.isEmpty
      ? null
      : 'Departamento de $departamento';

  static double _measure(
    BuildContext context,
    String text,
    TextStyle style, {
    required int maxLines,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  // Posiciones verticales (desde el borde superior de la cabecera).
  double get _shieldBigTop => topInset + _toolbar + 10;
  double get _expandedTextTop => _shieldBigTop + _shieldBig + 10;
  double get _rowTop => topInset + _toolbar + _rowOffset;

  @override
  double get minExtent => topInset + _toolbar + _collapsedExtra;

  @override
  double get maxExtent {
    final department = departmentHeight > 0 ? 4 + departmentHeight : 0;
    final expanded = _expandedTextTop + nameHeight + department + 16;
    // Siempre mayor que `minExtent`: el escudo grande + el nombre ya lo superan,
    // pero así un estilo raro no deja la cabecera sin recorrido.
    return expanded > minExtent ? expanded : minExtent + 1;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final textColor = getAdaptiveColor(
      primary,
      Colors.white,
      const Color(0xFF181E31),
    );

    final range = maxExtent - minExtent;
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final expandedOpacity = (1 - t / 0.5).clamp(0.0, 1.0);
    final collapsedOpacity = ((t - 0.5) / 0.5).clamp(0.0, 1.0);

    final shieldSize = lerpDouble(_shieldBig, _rowShield, t)!;
    final shieldLeft = lerpDouble((width - _shieldBig) / 2, _rowInset, t)!;
    final shieldTop = lerpDouble(_shieldBigTop, _rowTop, t)!;
    final department = _departmentLabel(departamento);

    return ClipRect(
      child: Container(
        color: primary,
        child: Stack(
          children: [
            // ---- Desplegada: nombre y departamento bajo el escudo ----
            Positioned(
              left: _expandedTextInset,
              right: _expandedTextInset,
              top: _expandedTextTop,
              child: IgnorePointer(
                child: Opacity(
                  key: expandedKey,
                  opacity: expandedOpacity,
                  child: isLoading
                      ? const _LoadingTexts()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              design.nombreAlcaldia,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: _expandedNameStyle.copyWith(
                                color: textColor,
                              ),
                            ),
                            if (department != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                department,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: _expandedDepartmentStyle.copyWith(
                                  color: textColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
            // ---- Recogida: nombre y departamento a la derecha del escudo ----
            if (!isLoading)
              Positioned(
                left: _rowInset,
                right: _rowInset,
                top: _rowTop,
                child: IgnorePointer(
                  child: Opacity(
                    key: collapsedKey,
                    opacity: collapsedOpacity,
                    // El espaciador fija el alto mínimo en el del escudo y deja
                    // el texto centrado respecto a él, como en Historial.
                    child: Row(
                      children: [
                        const SizedBox(
                          width: _rowShield + _rowGap,
                          height: _rowShield,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                design.nombreAlcaldia,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _collapsedNameStyle.copyWith(
                                  color: textColor,
                                ),
                              ),
                              if (department != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  department,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _collapsedDepartmentStyle.copyWith(
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // ---- Escudo: se desplaza y se encoge con el scroll ----
            Positioned(
              left: shieldLeft,
              top: shieldTop,
              child: isLoading
                  ? ShimmerPlaceholder(
                      width: shieldSize,
                      height: shieldSize,
                      borderRadius: lerpDouble(12, 8, t)!,
                    )
                  : MunicipalityShield(
                      url: design.escudoUrl,
                      size: shieldSize,
                      radius: lerpDouble(12, 8, t)!,
                    ),
            ),
            // ---- Botones (siempre visibles, fijos) ----
            Positioned(
              left: AppBackButton.edgeInset,
              top: topInset + (_toolbar - AppBackButton.size) / 2,
              child: AppBackButton(
                onPressed: onBack,
                style: AppBackButtonStyle.light,
              ),
            ),
            Positioned(
              right: _menuInset,
              top: topInset + (_toolbar - _menuSize) / 2,
              child: GestureDetector(
                onTap: onMenu,
                child: Container(
                  width: _menuSize,
                  height: _menuSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.menu, color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant MainHeaderDelegate oldDelegate) {
    return oldDelegate.design != design ||
        oldDelegate.departamento != departamento ||
        oldDelegate.isLoading != isLoading ||
        oldDelegate.topInset != topInset ||
        oldDelegate.width != width ||
        oldDelegate.nameHeight != nameHeight ||
        oldDelegate.departmentHeight != departmentHeight;
  }
}

/// Esqueleto de nombre y departamento (equivalente a `MainHeaderPlaceHolder`).
class _LoadingTexts extends StatelessWidget {
  const _LoadingTexts();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShimmerPlaceholder(width: 180, height: 22, borderRadius: 6),
        SizedBox(height: 8),
        ShimmerPlaceholder(width: 120, height: 14, borderRadius: 6),
      ],
    );
  }
}
