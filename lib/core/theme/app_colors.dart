import 'package:flutter/material.dart';

/// Subconjunto de tokens de color portados de `ui/theme/Color.kt` del proyecto
/// base (Kotlin/Compose). Estos valores son **fijos** (no dependen del municipio):
/// el diseño del login/registro del base usa estos colores tal cual, no el
/// `colorScheme` dinámico. Mantener el comentario con el nombre original.
class AppColors {
  AppColors._();

  /// `primarycolor` — navy de marca.
  static const primary = Color(0xFF181E31);

  /// `buttoncolorsOptionScreen` — CTA de login/registro (botones celestes).
  static const buttonOptionScreen = Color(0xFF41ACDD);

  /// `buttoncolorslogin` — azul de acento (dots del carrusel, etc.).
  static const loginBlue = Color(0xFF4364CD);

  /// `bottomSheetsColor`.
  static const bottomSheet = Color(0xFF1F1831);

  /// Campo oscuro de `AuthScreen.kt` (`grayField`).
  static const authField = Color(0xFF3D3D4E);

  /// `Gray300` — fondo del ModalBottomSheet de login.
  static const gray300 = Color(0xFFE0E0E0);

  /// `Gray400` — placeholders.
  static const gray400 = Color(0xFF9CA3AF);

  /// `Gray600`.
  static const gray600 = Color(0xFF7E7E7E);

  /// `Gray900`.
  static const gray900 = Color(0xFF212121);

  /// `Green` — check de éxito de registro.
  static const successGreen = Color(0xFF42A345);

  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
}
