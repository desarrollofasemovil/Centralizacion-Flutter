import 'package:flutter/material.dart';

/// Tokens de color del tutorial (hoja de especificaciones del diseño). Solo
/// [primary] y sus tintes cambian por alcaldía; el resto es fijo: el tutorial
/// es claro siempre, como el diseño.
class TutorialPalette {
  const TutorialPalette._(this.primary, this.tint10, this.tint20);

  factory TutorialPalette.from(Color backendPrimary) {
    final primary = accessiblePrimary(backendPrimary);
    return TutorialPalette._(
      primary,
      Color.lerp(Colors.white, primary, .10)!,
      Color.lerp(Colors.white, primary, .20)!,
    );
  }

  final Color primary;

  /// Fondos, botón Atrás, letras de la guía de PQRSDF.
  final Color tint10;

  /// Formas internas y chips.
  final Color tint20;

  static const onPrimary = Colors.white;
  static const surface = Colors.white;

  /// Tarjetas recortadas de la app.
  static const panel = Color(0xFFF2F3F5);
  static const onSurface = Color(0xFF1B1C1F);
  static const onSurfaceVar = Color(0xFF44474E);

  /// Texto de las tarjetas recortadas.
  static const cropText = Color(0xFF2B2D31);
  static const cropMuted = Color(0xFF5B5E66);
  static const dotOff = Color(0xFFC4C7CF);
  static const successIcon = Color(0xFF43A047);
  static const successText = Color(0xFF2E7D32);
  static const pendingIcon = Color(0xFFF5B800);
  static const pendingText = Color(0xFF8A5A00);

  /// Sombra de las tarjetas recortadas: (0, 10), blur 28, #001E32 al 16 %.
  static const cardShadow = [
    BoxShadow(offset: Offset(0, 10), blurRadius: 28, color: Color(0x29001E32)),
  ];

  /// Sombra de los íconos satélite: (0, 6), blur 16, al 14 %.
  static const satelliteShadow = [
    BoxShadow(offset: Offset(0, 6), blurRadius: 16, color: Color(0x24001E32)),
  ];

  /// Contraste mínimo del primario contra blanco (AA, texto normal).
  static const minContrast = 4.5;

  /// El primario tal cual si pasa AA contra blanco; si no, se oscurece en
  /// pasos de 4 % de luminosidad (HSL) hasta que pase. El texto en primario
  /// va sobre blanco o sobre [tint10], y el blanco va sobre el primario.
  static Color accessiblePrimary(Color color) {
    var hsl = HSLColor.fromColor(color.withValues(alpha: 1));
    var current = hsl.toColor();
    while (contrastOnWhite(current) < minContrast && hsl.lightness > 0) {
      hsl = hsl.withLightness((hsl.lightness - .04).clamp(0.0, 1.0));
      current = hsl.toColor();
    }
    return current;
  }

  static double contrastOnWhite(Color color) =>
      1.05 / (color.computeLuminance() + .05);
}
