import 'package:flutter/painting.dart';

/// Estilos de `ui/theme/Type.kt` (`Typography`) que usan los diálogos del
/// original.
///
/// La app Flutter no define un `TextTheme` propio (usa el M3 por defecto), así
/// que `textTheme.titleLarge` aquí es 22 regular, mientras que en Kotlin es
/// Roboto **Bold** 22. Para que los diálogos se vean igual se portan los
/// estilos exactos en lugar de heredar el `TextTheme`. La familia es la del
/// sistema (Roboto en Android, SF en iOS), igual que el resto de la app.
///
/// `lineHeight` de Compose (en sp) → `height` de Flutter (multiplicador):
/// `lineHeight / fontSize`. Si un llamador cambia el `fontSize` (como hace
/// Compose con `fontSize = 18.sp` sobre `bodyMedium`), el `lineHeight` en sp se
/// conserva, así que el multiplicador se recalcula con [withFontSize].
abstract final class DialogTypography {
  /// `titleLarge`: RobotoBold 22sp, lineHeight 22sp, letterSpacing 0.2sp.
  static const titleLarge = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 22,
    height: 22 / 22,
    letterSpacing: 0.2,
  );

  /// `titleMedium`: RobotoBold 20sp, lineHeight 20sp, letterSpacing 0.2sp.
  static const titleMedium = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 20 / 20,
    letterSpacing: 0.2,
  );

  /// `headlineMedium`: RobotoBold 18sp, lineHeight 18sp, letterSpacing 0.2sp.
  static const headlineMedium = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    height: 18 / 18,
    letterSpacing: 0.2,
  );

  /// `headlineSmall`: RobotoBold 16sp, lineHeight 16sp, letterSpacing 0.1sp.
  /// También es el estilo del título de un `AlertDialog` M3 de Compose.
  static const headlineSmall = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 16 / 16,
    letterSpacing: 0.1,
  );

  /// `bodyMedium`: Roboto regular 16sp, lineHeight 16sp, letterSpacing 0.2sp.
  /// También es el estilo del texto de un `AlertDialog` M3 de Compose.
  static const bodyMedium = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 16 / 16,
    letterSpacing: 0.2,
  );

  /// `bodySmall`: Roboto regular 12sp, lineHeight 14sp.
  static const bodySmall = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 14 / 12,
  );

  /// Equivalente a `style.copy(fontSize = x.sp)` de Compose: cambia el tamaño
  /// conservando el `lineHeight` absoluto del estilo base.
  static TextStyle withFontSize(TextStyle base, double fontSize) {
    final lineHeight = base.fontSize! * base.height!;
    return base.copyWith(fontSize: fontSize, height: lineHeight / fontSize);
  }
}
