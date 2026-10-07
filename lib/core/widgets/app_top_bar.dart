import 'package:flutter/material.dart';

import 'app_back_button.dart';

/// Barra superior simple: botón de retroceso circular + título. Port del
/// `TopAppBar` que el original repite en Configuración, Editar perfil, Cambiar
/// contraseña, Ayuda, etc.:
///
/// ```kotlin
/// TopAppBar(
///     title = { Text(text = "...", modifier = Modifier.padding(start = 15.dp)) },
///     navigationIcon = { IconButton(modifier = Modifier.padding(start = 10.dp).size(35.dp), ...) },
/// )
/// ```
///
/// Fija el tamaño y la posición del [AppBackButton] (a
/// [AppBackButton.edgeInset] del borde, centrado en [AppBackButton.barHeight])
/// para que el botón quede idéntico en todas las pantallas. Antes cada pantalla
/// armaba su `AppBar` a mano y el botón salía de tamaños y alturas distintas.
///
/// Para cabeceras con insignia que colapsan (PQRD, Certificados, Historial) usa
/// `TopBarNavigationScaffold`.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    required this.onBack,
    this.backStyle = AppBackButtonStyle.filled,
    this.backgroundColor,
    this.foregroundColor,
    this.titleStyle,
    this.centerTitle = false,
    this.actions,
  });

  /// Null deja la barra solo con el botón (p. ej. Consulta de impuesto, que
  /// pinta su título dentro del cuerpo).
  final String? title;
  final VoidCallback onBack;

  /// `filled` sobre fondo claro, `light` sobre el color del municipio.
  final AppBackButtonStyle backStyle;

  /// Fondo de la barra. Si es null usa el del tema (`AppBarTheme` o `surface`).
  final Color? backgroundColor;

  /// Color del título. Si es null usa el del tema o `onSurface`.
  final Color? foregroundColor;

  /// Se mezcla sobre `titleLarge` (p. ej. para poner el título en negrita).
  final TextStyle? titleStyle;
  final bool centerTitle;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(AppBackButton.barHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor =
        foregroundColor ??
        theme.appBarTheme.foregroundColor ??
        theme.colorScheme.onSurface;

    return AppBar(
      toolbarHeight: AppBackButton.barHeight,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: AppBackButton.edgeInset + AppBackButton.size,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppBackButton.edgeInset),
        child: AppBackButton(
          onPressed: onBack,
          style: backStyle,
          tooltip: 'Volver',
        ),
      ),
      titleSpacing: 15,
      centerTitle: centerTitle,
      title: title == null
          ? null
          : Text(
              title!,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: titleColor)
                  .merge(titleStyle),
            ),
      actions: actions,
    );
  }
}
