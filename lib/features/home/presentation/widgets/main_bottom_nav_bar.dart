import 'package:flutter/material.dart';

class BottomNavItem {
  final String label;
  final IconData icon;
  final String route;

  const BottomNavItem({
    required this.label,
    required this.icon,
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

    final adaptiveUnselectedIconColor = adaptiveSelectedIconColor.withValues(alpha: 0.7);

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
      darkerPrimaryColor = hsl.withLightness((hsl.lightness * 0.9).clamp(0.0, 1.0)).toColor();
    }

    final items = [
      const BottomNavItem(label: "Inicio", icon: Icons.home, route: "inicio"),
      const BottomNavItem(label: "Noticias", icon: Icons.newspaper, route: "noticias"),
      const BottomNavItem(label: "Portal", icon: Icons.language, route: "portal"),
      const BottomNavItem(label: "Historial", icon: Icons.history, route: "historial"),
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
        child: NavigationBar(
          backgroundColor: primaryColor,
          indicatorColor: darkerPrimaryColor,
          selectedIndex: selectedIndex,
          onDestinationSelected: onTap,
          destinations: items.map((item) {
            final isSelected = items.indexOf(item) == selectedIndex;
            return NavigationDestination(
              icon: Icon(
                item.icon,
                color: isSelected ? adaptiveSelectedIconColor : adaptiveUnselectedIconColor,
                size: 25,
              ),
              label: item.label,
            );
          }).toList(),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
    );
  }
}
