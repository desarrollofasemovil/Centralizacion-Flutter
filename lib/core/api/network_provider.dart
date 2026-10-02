import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// Las 6 base URLs de los microservicios (puerto de `NetworkProvider.kt`).
///
/// El backend se consume **sin cambios** (BACKEND §2). Todas son HTTPS (iOS lo
/// exige). La base URL local HTTP comentada del proyecto Android
/// (`http://192.168.20.198:45600/`) y `usesCleartextTraffic` NO se portan
/// (CLAUDE.md regla 6).
class NetworkProvider {
  NetworkProvider._();

  static const String _centralizacionApiUrl = 'https://apicentralizate.1cero1.com/';
  static const String _taxApiUrl = 'https://apidatamovil.1cero1.com/api/';
  static const String _pqrdApiUrl = 'https://tramitesservices.1cero1.com/ApiTramites/api/';
  static const String _autoliquidablesApiUrl = 'https://autoliquidables.1cero1.com/';
  static const String _googleApiUrl = 'https://people.googleapis.com/';
  static const String _googleWeatherApiUrl = 'https://weather.googleapis.com/';

  /// API principal: usuarios, auth, municipios, departamentos, recordatorios,
  /// historial de pagos, emails, fintech, personas invitadas. Es la base del
  /// Retrofit "principal".
  static String get centralizacionApiUrl => _proxied(_centralizacionApiUrl);

  /// Impuestos (consulta + PDF) y pasarela de pago Bancolombia.
  static String get taxApiUrl => _proxied(_taxApiUrl);

  /// PQRD (listados + inserción) y solicitud de trámites.
  static String get pqrdApiUrl => _proxied(_pqrdApiUrl);

  /// Generales: departamentos y ciudades por departamento (formularios PQRD/registro).
  static String get autoliquidablesApiUrl => _proxied(_autoliquidablesApiUrl);

  /// Google People API — perfil del usuario tras login con Google.
  static String get googleApiUrl => _proxied(_googleApiUrl);

  /// Google Weather API. **Deshabilitado** en el proyecto original (clima
  /// comentado en `MunicipalityViewModel`). Decidir en migración si se reactiva.
  static String get googleWeatherApiUrl => _proxied(_googleWeatherApiUrl);

  /// Ninguno de estos backends envía headers CORS (confirmado: el preflight
  /// `OPTIONS` responde 405 y el `GET` no trae `Access-Control-Allow-Origin`),
  /// así que el navegador bloquea las respuestas antes de que Dio las vea.
  /// Solo en debug web se reenruta a través de `tool/web_cors_proxy.dart`
  /// (correr con `dart run tool/web_cors_proxy.dart`), que reenvía tal cual al
  /// backend real y agrega los headers CORS. Release/móvil/desktop pegan
  /// siempre directo al backend, sin pasar por aquí (regla de oro §1: el
  /// backend se consume sin cambios).
  static String _proxied(String url) =>
      (kIsWeb && kDebugMode) ? 'http://localhost:8899/$url' : url;
}
