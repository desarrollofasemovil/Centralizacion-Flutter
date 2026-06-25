import 'package:flutter/material.dart';

class ServiciosPublicosTheme {
  // Brand colors
  static const Color primaryButton = Color(0xFF5B58FF);
  static const Color secondaryTeal = Color(0xFF007AFF); // iOS blue/teal
  static const Color tertiaryGreen = Color(0xFF34C759); // iOS green
  static const Color errorRed = Color(0xFFFF3B30); // iOS red
  static const Color pendingOrange = Color(0xFFFF9500);

  static const Color background = Color(0xFFF4F4F6);
  static const Color darkCard = Color(0xFF161C2D);
  static const Color darkNavy = Color(0xFF1C1C2E);
  static const Color darkText = Color(0xFF0D1326);
  static const Color grayText = Color(0xFF6B6E78);
  static const Color inputBg = Color(0xFFEAEAEA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryButton,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryButton,
        onPrimary: Colors.white,
        secondary: secondaryTeal,
        onSecondary: Colors.white,
        tertiary: tertiaryGreen,
        onTertiary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        surface: Colors.white,
        onSurface: darkText,
        surfaceContainerLow: Color(0xFFF9F9FB),
        surfaceContainerHigh: Color(0xFFE5E5EA),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 2,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryButton,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: primaryButton,
        onPrimary: Colors.white,
        secondary: secondaryTeal,
        onSecondary: Colors.white,
        tertiary: tertiaryGreen,
        onTertiary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        surface: Color(0xFF1C1C1E),
        onSurface: Colors.white,
        surfaceContainerLow: Color(0xFF2C2C2E),
        surfaceContainerHigh: Color(0xFF3C3C3E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1C1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1C1C1E),
        elevation: 2,
      ),
    );
  }
}
