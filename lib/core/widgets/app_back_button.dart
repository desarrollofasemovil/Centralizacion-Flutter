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
///
/// Siempre mide [size] aunque el padre le imponga restricciones estrictas (p. ej.
/// el `leading` de un `AppBar`, que antes lo estiraba a ~46 px). Para que quede
/// en el mismo sitio en todas las pantallas, colócalo con [AppTopBar] o, en
/// cabeceras propias, a [edgeInset] del borde y centrado en una franja de
/// [barHeight] bajo la barra de estado.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    required this.onPressed,
    this.style = AppBackButtonStyle.filled,
    this.tooltip = 'Atrás',
    this.backgroundColor,
    this.iconColor,
  });

  final VoidCallback onPressed;
  final AppBackButtonStyle style;
  final String tooltip;

  /// Sobrescriben los colores de [style] (solo para fondos especiales, como la
  /// hoja oscura del login).
  final Color? backgroundColor;
  final Color? iconColor;

  /// Lado del botón y tamaño del ícono, tal cual el original (35.dp / 20.dp).
  static const double size = 35;
  static const double iconSize = 20;

  /// Distancia del botón al borde izquierdo: `padding(start = 10.dp)` del
  /// original + los 4.dp de inset del `navigationIcon` del `TopAppBar` M3.
  static const double edgeInset = 14;

  /// Alto de la barra donde va el botón (`TopAppBar` M3 = 64.dp). El botón se
  /// centra verticalmente en esta franja.
  static const double barHeight = 64;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = style == AppBackButtonStyle.light;
    final background =
        backgroundColor ?? (isLight ? Colors.white : scheme.primary);
    final foreground =
        iconColor ?? (isLight ? scheme.primary : scheme.onPrimary);

    // `Center` con factores 1: con restricciones holgadas mide justo el botón;
    // con restricciones estrictas ocupa lo que le den y centra el círculo sin
    // deformarlo.
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: Semantics(
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
      ),
    );
  }
}
