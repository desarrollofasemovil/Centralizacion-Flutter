import 'package:flutter/material.dart';

/// Estilo del botón de retroceso, según el fondo sobre el que se dibuja.
enum AppBackButtonStyle {
  /// Círculo relleno con el color primario del municipio e ícono `onPrimary`.
  /// Es el del original cuando la barra va sobre fondo claro (`Color.Transparent`
  /// o `background`): Editar perfil, Configuración, Consulta de impuesto,
  /// Respuesta de consulta, Cursos y Escenarios deportivos.
  filled,

  /// Círculo blanco con el ícono en color primario. Es el del original cuando la
  /// barra va sobre el color del municipio: `MainTopBar` y `TopbarNavigation`
  /// (Home, PQRD, Certificados, PSV, Historial).
  light,
}

/// Botón de retroceso circular compartido. Port del `IconButton` que el original
/// repite en cada pantalla:
///
/// ```kotlin
/// IconButton(
///     onClick = ...,
///     modifier = Modifier
///         .padding(start = 10.dp)
///         .background(<color>, shape = RoundedCornerShape(40.dp))
///         .size(35.dp)
/// ) { Icon(Icons.Default.ArrowBackIosNew, tint = <tint>, modifier = Modifier.size(20.dp)) }
/// ```
///
/// Antes vivía duplicado como `_CircleBackButton` / `_CircularBackButton` en seis
/// pantallas, con tamaños de ícono distintos (18 vs 20 px).
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    required this.onPressed,
    this.style = AppBackButtonStyle.filled,
    this.tooltip = 'Atrás',
  });

  final VoidCallback onPressed;
  final AppBackButtonStyle style;
  final String tooltip;

  /// Lado del botón y tamaño del ícono, tal cual el original (35.dp / 20.dp).
  static const double size = 35;
  static const double iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = style == AppBackButtonStyle.light;
    final background = isLight ? Colors.white : scheme.primary;
    final foreground = isLight ? scheme.primary : scheme.onPrimary;

    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.arrow_back_ios_new,
              size: iconSize,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
