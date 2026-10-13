import 'package:flutter/foundation.dart';

/// Las 6 base URLs de los microservicios (puerto de `NetworkProvider.kt`).
///
/// El backend se consume **sin cambios** (BACKEND §2). Todo lo que puede
/// publicarse es HTTPS (iOS lo exige). La URL HTTP del servidor de pruebas
/// (`http://192.168.20.198:45600/`) existe **solo** como override de debug en
/// Android, apagado por defecto (ver [_devServerEnabled]; CLAUDE.md regla 6).
/// `usesCleartextTraffic` no se porta: el permiso de cleartext vive en el
/// `network_security_config` del source set `debug`, limitado a esa IP.
class NetworkProvider {
  NetworkProvider._();

  /// **URL oficial de producción** de la API Centralízate. Es la única que
  /// puede usar un build de `release` o `profile`: [centralizacionApiUrl] no
  /// tiene ninguna otra rama alcanzable fuera de debug.
  static const String prodCentralizacionApiUrl =
      'https://apicentralizate.1cero1.com/';

  /// Servidor de pruebas (IIS, API `develop`, BD `DLLO3`). Solo en la LAN de la
  /// oficina o por VPN, y en HTTP plano: por eso el override es solo Android
  /// debug (iOS lo bloquea por ATS). Ver BACKEND §2.
  static const String devCentralizacionApiUrl = 'http://192.168.20.198:45600/';

  static const String _taxApiUrl = 'https://apidatamovil.1cero1.com/api/';
  static const String _pqrdApiUrl =
      'https://tramitesservices.1cero1.com/ApiTramites/api/';
  static const String _autoliquidablesApiUrl =
      'https://autoliquidables.1cero1.com/';
  static const String _googleApiUrl = 'https://people.googleapis.com/';
  static const String _googleWeatherApiUrl = 'https://weather.googleapis.com/';

  /// Las 6 base URLs que la app puede usar en producción. Existe para que el
  /// test pueda afirmar que ninguna es cleartext.
  static const List<String> productionBaseUrls = [
    prodCentralizacionApiUrl,
    _taxApiUrl,
    _pqrdApiUrl,
    _autoliquidablesApiUrl,
    _googleApiUrl,
    _googleWeatherApiUrl,
  ];

  /// Activa el override: `--dart-define=USE_DEV_SERVER=true`. No tiene efecto
  /// fuera de debug, así que no hace falta quitarlo antes de un release.
  static const bool _useDevServer = bool.fromEnvironment(
    'USE_DEV_SERVER',
    defaultValue: false,
  );

  /// Condiciones del override, todas obligatorias:
  ///
  /// * `kDebugMode && !kReleaseMode && !kProfileMode`: son constantes de
  ///   compilación, así que el compilador AOT elimina la rama entera del
  ///   binario de release/profile en vez de dejarla muerta dentro.
  /// * `!kIsWeb` y Android: la URL es cleartext y solo el `debug` de Android
  ///   trae la excepción. Se usa `defaultTargetPlatform` (no `dart:io`
  ///   `Platform`) para que el archivo siga compilando en web.
  static bool get _devServerEnabled =>
      kDebugMode &&
      !kReleaseMode &&
      !kProfileMode &&
      _useDevServer &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;

  /// `true` si [centralizacionApiUrl] apunta al servidor de pruebas. La app lo
  /// usa para mostrar la marca "API DEV" y no confundir datos de prueba con
  /// producción.
  static bool get isUsingDevServer => _devServerEnabled;

  /// API principal: usuarios, auth, municipios, departamentos, recordatorios,
  /// historial de pagos, emails, fintech, personas invitadas, cursos y
  /// escenarios. Es la base del Retrofit "principal" y la única que tiene
  /// servidor de pruebas.
  static String get centralizacionApiUrl => _devServerEnabled
      ? devCentralizacionApiUrl
      : _proxied(prodCentralizacionApiUrl);

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
