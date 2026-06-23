import 'package:flutter/painting.dart';

import 'color_parser.dart';

/// Identidad visual del municipio en runtime — puerto del modelo `Design`
/// (mapeado del `Theme` DTO en `DataMappers.toDesignModel`).
///
/// Los colores ya vienen parseados; el escudo se carga con `cached_network_image`.
class Design {
  final String nombreAlcaldia;
  final String escudoUrl;
  final Color primaryColor;
  final Color secondaryColor;

  /// De `Theme.secondaryColorBlack` (usado en modo oscuro).
  final Color secondaryColorDark;

  /// Default negro (igual que el mapper).
  final Color onPrimaryColorLight;

  /// Default blanco (igual que el mapper).
  final Color onPrimaryColorDark;

  const Design({
    required this.nombreAlcaldia,
    required this.escudoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.secondaryColorDark,
    required this.onPrimaryColorLight,
    required this.onPrimaryColorDark,
  });

  /// Equivalente a `Theme.toDesignModel(alcaldiaName, shield)`: parsea los 6 hex
  /// del `Theme` DTO con sus mismos defaults por campo.
  factory Design.fromThemeHex({
    required String alcaldiaName,
    required String shieldUrl,
    String? primaryColor,
    String? secondaryColor,
    String? secondaryColorBlack,
    String? onPrimaryColorLight,
    String? onPrimaryColorDark,
  }) {
    return Design(
      nombreAlcaldia: alcaldiaName,
      escudoUrl: shieldUrl,
      primaryColor: parseColor(primaryColor),
      secondaryColor: parseColor(secondaryColor),
      secondaryColorDark: parseColor(secondaryColorBlack),
      onPrimaryColorLight:
          parseColor(onPrimaryColorLight, fallback: const Color(0xFF000000)),
      onPrimaryColorDark:
          parseColor(onPrimaryColorDark, fallback: const Color(0xFFFFFFFF)),
    );
  }
}
