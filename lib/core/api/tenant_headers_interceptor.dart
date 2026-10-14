import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../flavor/flavor_config.dart';
import '../utils/app_info.dart';
import 'network_provider.dart';

/// Cabeceras multi-tenant de la API Centralízate (API `docs/api/multi-tenant.md`).
///
/// `AppTenantMiddleware` resuelve con `X-App-Id` la app cliente y su banco
/// patrocinador: qué municipios devuelven `GetMunicipality` /
/// `ByDepartamet_{id}`, qué overrides de trámites aplica `GetInfoBy{id}` y en qué
/// banco operan login, registro y `User/by-email`. Sin la cabecera la API cae a
/// la app legacy de Bancolombia, que es correcto para `municipios` pero no para
/// ningún otro flavor. `X-App-Version` y `X-Platform` hoy solo se registran.
///
/// Solo se agregan a peticiones hacia la API Centralízate (producción o el
/// servidor de pruebas, según [NetworkProvider.centralizacionApiUrl]). Impuestos,
/// PQRD, autoliquidables y Google son otros backends y no las reciben.
class TenantHeadersInterceptor extends Interceptor {
  TenantHeadersInterceptor({
    String Function()? centralizacionBaseUrl,
    String Function()? appIdentifier,
    String Function()? appVersion,
    String? Function()? platform,
  }) : _baseUrl = centralizacionBaseUrl ?? _defaultBaseUrl,
       _appIdentifier = appIdentifier ?? _defaultAppIdentifier,
       _appVersion = appVersion ?? _defaultAppVersion,
       _platform = platform ?? currentPlatformHeader;

  static const appIdHeader = 'X-App-Id';
  static const appVersionHeader = 'X-App-Version';
  static const platformHeader = 'X-Platform';

  final String Function() _baseUrl;
  final String Function() _appIdentifier;
  final String Function() _appVersion;
  final String? Function() _platform;

  static String _defaultBaseUrl() => NetworkProvider.centralizacionApiUrl;
  static String _defaultAppIdentifier() => FlavorConfig.instance.appIdentifier;
  static String _defaultAppVersion() => AppInfo.version;

  /// `android` / `ios`, los dos valores que documenta la API. En web y desktop
  /// no se envía: no son clientes registrados y la cabecera es opcional.
  static String? currentPlatformHeader() {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (NetworkProvider.isCentralizacionApi(options.uri, baseUrl: _baseUrl())) {
      options.headers[appIdHeader] = _appIdentifier();
      options.headers[appVersionHeader] = _appVersion();
      final platform = _platform();
      if (platform != null) options.headers[platformHeader] = platform;
    }
    handler.next(options);
  }
}
