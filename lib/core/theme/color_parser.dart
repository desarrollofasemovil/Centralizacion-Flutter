import 'package:flutter/painting.dart';

/// Color de respaldo por defecto: `Color.Gray` de Compose (`0xFF888888`),
/// igual que `parseColor(defaultColor = Color.Gray)` en el proyecto Android.
const Color kColorFallback = Color(0xFF888888);

/// Parsea los colores hex de `MunicipalityDTO.theme` (BACKEND §4.1).
///
/// Puerto **fiel** de `parseColor()` (`DataMappers.kt`):
/// - si es null/vacío → [fallback];
/// - quita únicamente el prefijo `0x` (no `#`, igual que `removePrefix("0x")`);
/// - exige **exactamente 8** dígitos ARGB (no rellena 6→8); si no, → [fallback];
/// - si no parsea como hex → [fallback].
///
/// Los defaults por campo replican el mapper:
/// `onPrimaryColorLight` → negro, `onPrimaryColorDark` → blanco, el resto gris.
Color parseColor(String? raw, {Color fallback = kColorFallback}) {
  if (raw == null || raw.trim().isEmpty) return fallback;

  var colorStr = raw.trim();
  if (colorStr.startsWith('0x')) {
    colorStr = colorStr.substring(2);
  }
  if (colorStr.length != 8) return fallback;

  final value = int.tryParse(colorStr, radix: 16);
  if (value == null) return fallback;

  return Color(value);
}
