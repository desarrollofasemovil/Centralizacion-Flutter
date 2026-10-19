import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tramites/domain/info_tramite.dart';

/// Capa de analíticas sobre Firebase Analytics (BACKEND §6/§9).
/// Centraliza el logueo de eventos en un solo lugar para mayor flexibilidad.
///
/// Catálogo de eventos y propiedades: `docs/ANALITICA_EVENTOS.md`. Los nombres
/// de los clics de trámites y de la barra inferior se conservan del original
/// Kotlin (`MainViewModel.kt`) para no partir las series históricas de GA4;
/// lo que cambia son los parámetros (antes mandaban la ruta o la URL completa,
/// que GA4 corta a 100 caracteres y no se puede agrupar).
///
/// La instancia de Firebase se resuelve en cada llamada y cualquier fallo se
/// traga: la analítica nunca debe romper un flujo (ni las pruebas de widgets,
/// donde Firebase no está inicializado).
class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics Function() _analytics;

  /// Límite de GA4 para el valor de un parámetro de evento.
  static const int _maxParamLength = 100;

  /// Límite de GA4 para el valor de una propiedad de usuario.
  static const int _maxUserPropertyLength = 36;

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics().logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics().logScreenView(screenName: screenName);
    } catch (_) {}
  }

  Future<void> logLogin(String method) async {
    try {
      await _analytics().logLogin(loginMethod: method);
    } catch (_) {}
  }

  Future<void> logSignUp(String method) async {
    try {
      await _analytics().logSignUp(signUpMethod: method);
    } catch (_) {}
  }

  Future<void> setUserId(String id) async {
    try {
      await _analytics().setUserId(id: id);
    } catch (_) {}
  }

  Future<void> setUserProperty(String name, String? value) async {
    try {
      await _analytics().setUserProperty(name: name, value: value);
    } catch (_) {}
  }

  // ── Municipio ──────────────────────────────────────────────────────────

  /// Municipio que el usuario está usando: queda como propiedad de usuario
  /// (`municipio`, `municipio_id`) para segmentar CUALQUIER evento y armar
  /// audiencias en GA4 / Firebase Messaging, y registra `seleccion_municipio`.
  ///
  /// Reemplaza el `event_<municipio>` del original, que creaba un nombre de
  /// evento distinto por municipio (GA4 admite 500 nombres por app) y no
  /// permitía cruzar el municipio con los demás eventos.
  Future<void> setMunicipality({required int id, required String name}) async {
    final slug = municipalitySlug(name);
    await setUserProperty(
      'municipio',
      _truncate(slug, _maxUserPropertyLength),
    );
    await setUserProperty('municipio_id', id.toString());
    await logEvent(
      'seleccion_municipio',
      parameters: {
        'municipio_id': id,
        'municipio': _truncate(slug, _maxParamLength),
      },
    );
  }

  // ── Trámites (Home) ────────────────────────────────────────────────────

  /// Clic en un trámite de la Home. Un evento por tipo de acción, con los
  /// mismos nombres del original (`clic_pqrds`, `clic_url_directa`, …).
  ///
  /// Para URLs se manda solo el dominio (`url_dominio`): la URL completa puede
  /// traer parámetros del usuario y pasa del límite de 100 caracteres.
  Future<void> logTramiteClick(
    InfoTramite tramite, {
    required int municipalityId,
  }) async {
    final params = <String, Object>{
      'municipio_id': municipalityId,
      // `key` (el `code` del catálogo) es estable entre entornos y municipios;
      // `idtramite` no, pero es el que cruza con el backend.
      'tramite_codigo': _truncate(tramite.key, _maxParamLength),
      'tramite_id': tramite.idtramite,
      'tramite_nombre': _truncate(tramite.nombre, _maxParamLength),
    };

    if (!tramite.isActive) {
      await logEvent('clic_tramite_inactivo', parameters: params);
      return;
    }

    final action = tramite.accion;
    final String name;
    switch (action) {
      case ShowPqrds():
        name = 'clic_pqrds';
      case AbrirUrl(:final url):
        name = 'clic_url_directa';
        params['url_dominio'] = _host(url);
        params['requiere_datos'] = 'si';
      case AbrirUrlDirecto(:final url):
        name = 'clic_url_directa';
        params['url_dominio'] = _host(url);
        params['requiere_datos'] = 'no';
      case AbrirBotonPanico():
        name = 'clic_boton_panico';
      case NavegarANativo(:final ruta):
        name = 'clic_navegacion_nativa';
        params['ruta'] = _truncate(ruta, _maxParamLength);
      case NavegarACertificado():
        name = 'clic_certificado';
      case NavegarAConsultaImpuesto(:final taxId):
        name = 'clic_consulta_impuesto';
        params['impuesto_id'] = taxId;
      case NavegarAPagoSinValidacion(:final taxId):
        name = 'clic_psv';
        params['impuesto_id'] = taxId;
      case NavegarACursos(:final courseId):
        name = 'clic_cursos';
        params['curso_id'] = courseId;
      case NavegarAvenues(:final venueId):
        name = 'clic_venues';
        params['venue_id'] = venueId;
    }
    await logEvent(name, parameters: params);
  }

  // ── Barra inferior ─────────────────────────────────────────────────────

  /// Pestañas de la barra inferior de la Home. `clic_inicio` reemplaza el
  /// `clic_mainScreen` del original (único evento en camelCase).
  Future<void> logBottomNavClick(
    BottomNavDestination destination, {
    required int municipalityId,
  }) async {
    await logEvent(
      destination.eventName,
      parameters: {'municipio_id': municipalityId},
    );
  }

  // ── Registro ───────────────────────────────────────────────────────────

  /// Toque en "Registrarse" (o Google sin cuenta que cae al registro). El
  /// original mandaba aquí el `sign_up` estándar, que cuenta registros
  /// iniciados como completados; ahora `sign_up` va al terminar `createUser`.
  Future<void> logSignUpStarted(String method) async {
    await logEvent('inicio_registro', parameters: {'method': method});
  }

  static String _truncate(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);

  static String _host(String url) {
    final trimmed = url.trim();
    final parsed = Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'https://$trimmed',
    );
    final host = parsed?.host ?? '';
    return _truncate(host.isEmpty ? 'desconocido' : host, _maxParamLength);
  }
}

/// Métodos de autenticación tal como se reportan en `login` / `sign_up`.
abstract final class AuthMethod {
  static const String email = 'correo';
  static const String google = 'google';
}

/// Pestañas de `MainBottomNavBar`, en el orden de sus índices.
enum BottomNavDestination {
  inicio('clic_inicio'),
  noticias('clic_noticias'),
  portal('clic_portal'),
  historial('clic_historial');

  const BottomNavDestination(this.eventName);

  final String eventName;
}

/// Nombre del municipio normalizado: sin acentos, espacios → `_`, solo
/// `[a-zA-Z0-9_]`. Es la misma regla que `formatTopicName` del original
/// (`MunicipalityViewModel.kt`), así el tópico FCM y la propiedad de usuario
/// coinciden.
String municipalitySlug(String name) {
  const accents = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n',
    'Á': 'A', 'À': 'A', 'Ä': 'A', 'Â': 'A',
    'É': 'E', 'È': 'E', 'Ë': 'E', 'Ê': 'E',
    'Í': 'I', 'Ì': 'I', 'Ï': 'I', 'Î': 'I',
    'Ó': 'O', 'Ò': 'O', 'Ö': 'O', 'Ô': 'O',
    'Ú': 'U', 'Ù': 'U', 'Ü': 'U', 'Û': 'U',
    'Ñ': 'N',
  };
  final ascii = name.trim().split('').map((c) => accents[c] ?? c).join();
  return ascii
      .replaceAll(RegExp(r'\s'), '_')
      .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(() => FirebaseAnalytics.instance),
);
