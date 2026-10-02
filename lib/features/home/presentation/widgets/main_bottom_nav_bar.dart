import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavItem {
  final String label;

  /// Asset SVG del ícono, portado de los `R.drawable` del `enum Destination`
  /// original (icohome / iconoticias / icoportal / icohistorial). Antes se
  /// usaban íconos genéricos de Material, que no son los de la marca.
  final String iconAsset;
  final String route;

  const BottomNavItem({
    required this.label,
    required this.iconAsset,
    required this.route,
  });
}

class MainBottomNavBar extends StatelessWidget {
  final String selectedRoute;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    super.key,
    required this.selectedRoute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final adaptiveSelectedIconColor = primaryColor.computeLuminance() > 0.5
        ? const Color(0xFF212121) // Gray900
        : Colors.white;

    final adaptiveUnselectedIconColor = adaptiveSelectedIconColor.withValues(
      alpha: 0.7,
    );

    final Color darkerPrimaryColor;
    if (primaryColor.computeLuminance() < 0.5) {
      darkerPrimaryColor = Color.from(
        alpha: primaryColor.a,
        red: (primaryColor.r + 0.15).clamp(0.0, 1.0),
        green: (primaryColor.g + 0.15).clamp(0.0, 1.0),
        blue: (primaryColor.b + 0.15).clamp(0.0, 1.0),
      );
    } else {
      final hsl = HSLColor.fromColor(primaryColor);
      darkerPrimaryColor = hsl
          .withLightness((hsl.lightness * 0.9).clamp(0.0, 1.0))
          .toColor();
    }

    final items = [
      const BottomNavItem(
        label: "Inicio",
        iconAsset: "assets/images/icohome.svg",
        route: "inicio",
      ),
      const BottomNavItem(
        label: "Noticias",
        iconAsset: "assets/images/iconoticias.svg",
        route: "noticias",
      ),
      const BottomNavItem(
        label: "Portal",
        iconAsset: "assets/images/icoportal.svg",
        route: "portal",
      ),
      const BottomNavItem(
        label: "Historial",
        iconAsset: "assets/images/icohistorial.svg",
        route: "historial",
      ),
    ];

    int getSelectedIndex() {
      if (selectedRoute.contains('news')) return 1;
      if (selectedRoute.contains('portal')) return 2;
      if (selectedRoute.contains('history')) return 3;
      return 0;
    }

    final selectedIndex = getSelectedIndex();

    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        // NavigationBarTheme local: el color de las etiquetas y del indicador
        // debe ser el adaptativo sobre `primary` (port de selectedTextColor /
        // unselectedTextColor / indicatorColor de MainBottomNavBar.kt); sin
        // esto los labels usan onSurface del tema y se pierden sobre el fondo.
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final color = states.contains(WidgetState.selected)
                  ? adaptiveSelectedIconColor
                  : adaptiveUnselectedIconColor;
              return theme.textTheme.labelMedium?.copyWith(color: color) ??
                  TextStyle(color: color, fontSize: 12);
            }),
          ),
          child: NavigationBar(
            backgroundColor: primaryColor,
            indicatorColor: darkerPrimaryColor,
            selectedIndex: selectedIndex,
            onDestinationSelected: onTap,
            destinations: items.map((item) {
              final isSelected = items.indexOf(item) == selectedIndex;
              return NavigationDestination(
                icon: SvgPicture.asset(
                  item.iconAsset,
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? adaptiveSelectedIconColor
                        : adaptiveUnselectedIconColor,
                    BlendMode.srcIn,
                  ),
                ),
                label: item.label,
              );
            }).toList(),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
        ),
      ),
    );
  }
}
