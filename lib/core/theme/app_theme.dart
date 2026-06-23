import 'package:flutter/material.dart';

import 'design.dart';

/// Construcción del `ThemeData` dinámico desde el backend (CONVENCIONES §6,
/// FRONTEND §4). Replica `AlcaldiasTheme` / `InicialTheme` del proyecto Compose:
/// se parte de un esquema base de marca y se sobreescriben primary/secundary con
/// los colores del municipio (`Design`).

// ── Paleta base de marca (subconjunto de ui/theme/Color.kt) ──────────────────
const _brandPrimary = Color(0xFF181E31); // primarycolor
const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);
const _gray100 = Color(0xFFF5F5F5);
const _gray600 = Color(0xFF7E7E7E);
const _gray900 = Color(0xFF212121);
const _surfaceColor = Color(0xFFF3F4F6);
const _colorTextPrimary = Color(0xFF2C2E35);
const _darkRed = Color(0xFF7B1E3A);
const _lightRed = Color(0xFFFF1710);
const _red = Color(0xFFE53935);

/// Equivalente a `BrandLightColorScheme`.
final ColorScheme _brandLight = const ColorScheme.light().copyWith(
  primary: _brandPrimary,
  onPrimary: _white,
  primaryContainer: _gray100,
  secondary: _gray600,
  onSecondary: _gray100,
  surface: _surfaceColor,
  onSurface: _colorTextPrimary,
  onSurfaceVariant: _gray600,
  error: _darkRed,
  onError: _lightRed,
);

/// Equivalente a `BrandDarkColorScheme`.
final ColorScheme _brandDark = const ColorScheme.dark().copyWith(
  primary: _brandPrimary,
  onPrimary: _white,
  primaryContainer: _gray900,
  secondary: _gray100,
  onSecondary: _gray600,
  surface: _gray900,
  onSurface: _white,
  onSurfaceVariant: _gray100,
  error: _lightRed,
  onError: _black,
);

/// Tema dinámico del municipio — puerto de `AlcaldiasTheme`.
/// Sobre el esquema base de marca aplica los colores del [Design] del backend.
ThemeData buildAlcaldiasTheme(Design design, {bool dark = false}) {
  final base = dark ? _brandDark : _brandLight;
  final scheme = base.copyWith(
    primary: design.primaryColor,
    onPrimary: dark ? design.onPrimaryColorDark : design.onPrimaryColorLight,
    secondary: dark ? design.secondaryColorDark : design.secondaryColor,
    onSecondary: dark ? _gray100 : design.secondaryColor,
    error: dark ? _lightRed : _red,
  );
  return ThemeData(useMaterial3: true, colorScheme: scheme);
}

/// Tema neutro para Welcome / Selector de municipio — puerto de `InicialTheme`
/// (sin colores de municipio). No portamos el dynamic color (Material You) del
/// original; se usa la paleta de marca.
ThemeData buildInicialTheme({bool dark = false}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: dark ? _brandDark : _brandLight,
  );
}
