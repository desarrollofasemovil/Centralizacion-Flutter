import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/portal_externo/domain/portal_visit.dart';
import '../../features/reminders/domain/reminders_state.dart';
import '../../features/tramites/domain/info_tramite.dart';
import '../models/payment_history_dto.dart';

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
    await setUserProperty('municipio', _truncate(slug, _maxUserPropertyLength));
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

  // ── Embudo de pago por pasarela integrada (Fase 1) ─────────────────────

  /// Toque en "Consultar" del formulario de impuestos. `tipo_consulta` es el
  /// nombre del campo (p. ej. `Documento`), nunca el número consultado.
  Future<void> logTaxQuerySent({
    required int municipalityId,
    required int taxId,
    required String entityCode,
    required String queryField,
  }) async {
    await logEvent(
      'consulta_impuesto_enviada',
      parameters: {
        'municipio_id': municipalityId,
        'impuesto_id': taxId,
        'entidad_codigo': _truncate(entityCode, _maxParamLength),
        'tipo_consulta': _truncate(queryField, _maxParamLength),
      },
    );
  }

  /// Respuesta de la consulta: facturas encontradas, sin deuda (lista vacía)
  /// o error. Con facturas manda cuántas y el total en COP: es lo que el
  /// contribuyente *debe*, para compararlo con lo que termina pagando.
  Future<void> logTaxQueryResult({
    required int municipalityId,
    required int taxId,
    required TaxQueryOutcome outcome,
    int count = 0,
    int totalValue = 0,
    Object? error,
  }) async {
    await logEvent(
      'consulta_impuesto_resultado',
      parameters: {
        'municipio_id': municipalityId,
        'impuesto_id': taxId,
        'resultado': outcome.value,
        if (outcome == TaxQueryOutcome.found) ...{
          'cantidad': count,
          'valor_total': totalValue,
        },
        if (outcome == TaxQueryOutcome.error) 'motivo': errorReason(error),
      },
    );
  }

  /// Se abre la URL de la pasarela (pantalla «Procesando tu pago»). Solo el
  /// dominio: la URL trae el token de la transacción.
  Future<void> logGatewayOpened({
    required int municipalityId,
    required PaymentOrigin origin,
    required String paymentUrl,
    int? taxId,
  }) async {
    await logEvent(
      'pasarela_abierta',
      parameters: {
        'municipio_id': municipalityId,
        'origen': origin.value,
        'url_dominio': _host(paymentUrl),
        'impuesto_id': ?taxId,
      },
    );
  }

  /// Estado de un pago del historial después de sincronizarlo con la pasarela.
  /// [screen] dice dónde se verificó: el botón «Verificar estado» o el
  /// refresco del Historial (ahí no se sabe el origen del pago).
  Future<void> logPaymentVerified({
    required int municipalityId,
    required PaymentHistoryDTO payment,
    required VerificationScreen screen,
    PaymentOrigin? origin,
  }) async {
    await logEvent(
      'pago_verificado',
      parameters: {
        'municipio_id': municipalityId,
        'origen': ?origin?.value,
        'resultado': paymentResult(payment.idStatusType),
        'estado_id': payment.idStatusType,
        'pantalla': screen.value,
        'valor': payment.amount,
      },
    );
  }

  /// `purchase` estándar de GA4 (ingresos en los informes de monetización).
  /// Solo para pagos que el **backend** confirma aprobados; el monto es el del
  /// historial. `transaction_id` = id del historial: GA4 descarta un segundo
  /// `purchase` con el mismo id, así que verificar dos veces no duplica.
  Future<void> logPaymentApproved({
    required int municipalityId,
    required PaymentHistoryDTO payment,
  }) async {
    if (payment.idStatusType != kPaymentStatusApproved) return;
    await logEvent(
      'purchase',
      parameters: {
        'currency': 'COP',
        'value': payment.amount,
        'transaction_id': 'hist_${payment.id}',
        'municipio_id': municipalityId,
        'impuesto_id': _truncate(payment.idimpuesto, _maxParamLength),
      },
    );
  }

  /// Fallo en el camino al pago. [error] se reduce a un código ([errorReason]):
  /// el mensaje de Dio incluye la URL, que lleva el documento consultado.
  Future<void> logPaymentError({
    required int municipalityId,
    required PaymentOrigin origin,
    required PaymentStage stage,
    Object? error,
    String? reason,
  }) async {
    await logEvent(
      'pago_error',
      parameters: {
        'municipio_id': municipalityId,
        'origen': origin.value,
        'etapa': stage.value,
        'motivo': _truncate(reason ?? errorReason(error), _maxParamLength),
      },
    );
  }

  // ── Portales externos (Fase 2) ─────────────────────────────────────────

  /// Parámetros comunes de una visita a un portal externo de trámite.
  Map<String, Object> _portalParams(PortalVisit visit) => {
    'municipio_id': visit.municipalityId,
    'tramite_codigo': _truncate(visit.tramite.codigo, _maxParamLength),
    'tramite_id': visit.tramite.id,
    'tramite_nombre': _truncate(visit.tramite.nombre, _maxParamLength),
    'url_dominio': _host(visit.url),
  };

  /// El portal se abrió de verdad (pasó el aviso de sitio externo y, si hacía
  /// falta, el formulario de datos). `clic_url_directa` cuenta el toque; la
  /// diferencia entre los dos es quien abandona antes de salir de la app.
  Future<void> logPortalOpened(PortalVisit visit) async {
    await logEvent('portal_externo_abierto', parameters: _portalParams(visit));
  }

  /// El usuario volvió a la app desde el portal, tras [away] fuera.
  /// [appRestarted]: Android cerró la app mientras estaba en el portal y la
  /// visita se resolvió al volver a abrirla (el tiempo incluye el reinicio).
  Future<void> logPortalReturned(
    PortalVisit visit, {
    required Duration away,
    required bool appRestarted,
  }) async {
    await logEvent(
      'portal_externo_regreso',
      parameters: {
        ..._portalParams(visit),
        'segundos_fuera': away.inSeconds,
        'rango_tiempo': timeAwayRange(away),
        'app_reiniciada': appRestarted ? 'si' : 'no',
      },
    );
  }

  Future<void> logPortalSurveyShown(
    PortalVisit visit, {
    required Duration away,
  }) async {
    await logEvent(
      'encuesta_portal_mostrada',
      parameters: {
        ..._portalParams(visit),
        'rango_tiempo': timeAwayRange(away),
      },
    );
  }

  /// Respuesta de la microencuesta. [problem] solo con
  /// [PortalSurveyAnswer.problem].
  Future<void> logPortalSurveyAnswered(
    PortalVisit visit, {
    required Duration away,
    required PortalSurveyAnswer answer,
    PortalSurveyProblem? problem,
  }) async {
    await logEvent(
      'encuesta_portal_respuesta',
      parameters: {
        ..._portalParams(visit),
        'rango_tiempo': timeAwayRange(away),
        'respuesta': answer.value,
        if (problem != null) 'motivo': problem.value,
      },
    );
  }

  /// Cerró la encuesta sin terminarla, en el [step] en que iba.
  Future<void> logPortalSurveyDismissed(
    PortalVisit visit, {
    required PortalSurveyStep step,
  }) async {
    await logEvent(
      'encuesta_portal_descartada',
      parameters: {..._portalParams(visit), 'paso': step.value},
    );
  }

  // ── Recordatorios ──────────────────────────────────────────────────────

  /// Toque en una entrada para crear un recordatorio. `sesion` dice si ya
  /// tenía cuenta iniciada (sin ella se le pide iniciar sesión primero).
  Future<void> logReminderStarted({
    required int municipalityId,
    required ReminderOrigin origin,
    required bool hasSession,
  }) async {
    await logEvent(
      'recordatorio_iniciado',
      parameters: {
        'municipio_id': municipalityId,
        'origen': origin.value,
        'sesion': hasSession ? 'si' : 'no',
      },
    );
  }

  /// Abre "Mis recordatorios" desde el menú lateral o el aviso de la Home.
  Future<void> logRemindersOpened({
    required int municipalityId,
    required RemindersEntry entry,
  }) async {
    await logEvent(
      'recordatorios_abiertos',
      parameters: {'municipio_id': municipalityId, 'entrada': entry.value},
    );
  }

  /// Recordatorio guardado en el backend. `antelacion` es cuánto antes de la
  /// fecha se programó el aviso.
  Future<void> logReminderCreated({
    required ReminderOrigin origin,
    required String offset,
    int? municipalityId,
  }) async {
    await logEvent(
      'recordatorio_creado',
      parameters: {
        'municipio_id': ?municipalityId,
        'origen': origin.value,
        'antelacion': offset,
      },
    );
  }

  // ── Tutorial de primer uso ─────────────────────────────────────────────

  /// Se abre el tutorial. `recorrido` son las tarjetas que le tocaron a esta
  /// alcaldía (p. ej. `1-2A-3A-4-5-6A`).
  Future<void> logTutorialStarted({
    required int municipalityId,
    required TutorialOrigin origin,
    required String route,
    required int totalSteps,
  }) async {
    await logEvent(
      'tutorial_iniciado',
      parameters: {
        'municipio_id': municipalityId,
        'origen': origin.value,
        'recorrido': _truncate(route, _maxParamLength),
        'pasos': totalSteps,
      },
    );
  }

  /// Llega a una tarjeta (también la primera). `paso` empieza en 1.
  Future<void> logTutorialStepViewed({
    required int municipalityId,
    required TutorialOrigin origin,
    required int step,
    required String card,
  }) async {
    await logEvent(
      'tutorial_paso_visto',
      parameters: {
        'municipio_id': municipalityId,
        'origen': origin.value,
        'paso': step,
        'tarjeta': card,
      },
    );
  }

  /// Cierra el tutorial desde la última tarjeta: «Empezar» o, en la de
  /// cuenta, cualquiera de sus tres botones.
  Future<void> logTutorialCompleted({
    required int municipalityId,
    required TutorialOrigin origin,
    required int totalSteps,
    required TutorialClose close,
  }) async {
    await logEvent(
      'tutorial_completado',
      parameters: {
        'municipio_id': municipalityId,
        'origen': origin.value,
        'pasos': totalSteps,
        'cierre': close.value,
      },
    );
  }

  /// Lo cierra antes del final: «Omitir», o "atrás" en la primera tarjeta.
  Future<void> logTutorialSkipped({
    required int municipalityId,
    required TutorialOrigin origin,
    required int step,
    required String card,
  }) async {
    await logEvent(
      'tutorial_omitido',
      parameters: {
        'municipio_id': municipalityId,
        'origen': origin.value,
        'paso': step,
        'tarjeta': card,
      },
    );
  }

  /// Rango del tiempo fuera, para agrupar en GA4 sin una dimensión por
  /// segundo: `menos_15s`, `15_60s`, `1_3min`, `3_10min`, `mas_10min`.
  static String timeAwayRange(Duration away) {
    final s = away.inSeconds;
    if (s < 15) return 'menos_15s';
    if (s < 60) return '15_60s';
    if (s < 180) return '1_3min';
    if (s < 600) return '3_10min';
    return 'mas_10min';
  }

  /// `aprobado` / `pendiente` / `rechazado` según `idStatusType` (tabla
  /// `Availibity`: 1 APROBADA, 2 COMENZADA, 3 FALLIDA, 4 EXPIRADA).
  static String paymentResult(int idStatusType) => switch (idStatusType) {
    kPaymentStatusApproved => 'aprobado',
    2 => 'pendiente',
    3 || 4 => 'rechazado',
    _ => 'desconocido',
  };

  /// Código corto y sin datos del usuario para el parámetro `motivo`.
  static String errorReason(Object? error) {
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => 'timeout',
        DioExceptionType.connectionError => 'sin_conexion',
        DioExceptionType.badResponse =>
          'http_${error.response?.statusCode ?? 'desconocido'}',
        DioExceptionType.cancel => 'cancelado',
        _ => 'red',
      };
    }
    if (error == null) return 'desconocido';
    return _truncate(error.runtimeType.toString(), _maxParamLength);
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

/// Resultado de `consulta_impuesto_resultado`.
enum TaxQueryOutcome {
  found('encontrado'),
  noDebt('sin_deuda'),
  error('error');

  const TaxQueryOutcome(this.value);

  final String value;
}

/// De dónde viene un pago: consulta de impuestos, pago sin validación o
/// certificados (las tres terminan en «Procesando tu pago»).
enum PaymentOrigin {
  taxQuery('consulta_impuesto'),
  psv('psv'),
  certificate('certificado');

  const PaymentOrigin(this.value);

  final String value;
}

/// Paso del pago en el que ocurrió un `pago_error`.
enum PaymentStage {
  /// Registro previo en el historial (`POST api/PaymentHistory/`).
  historyRegistration('registro_historial'),

  /// Creación de la transacción en la pasarela.
  transaction('transaccion'),

  /// La pasarela no devolvió URL.
  noUrl('sin_url'),

  /// Sincronización del estado al verificar.
  verification('verificacion');

  const PaymentStage(this.value);

  final String value;
}

/// Dónde se verificó el estado de un pago.
enum VerificationScreen {
  processing('procesamiento'),
  history('historial');

  const VerificationScreen(this.value);

  final String value;
}

/// Respuesta a "¿Pudiste hacer tu pago?" (`encuesta_portal_respuesta`).
enum PortalSurveyAnswer {
  paid('pague'),
  checkedNotPaid('consulte_no_pague'),
  problem('problema'),
  justBrowsing('solo_mirando');

  const PortalSurveyAnswer(this.value);

  final String value;
}

/// Motivo cuando la respuesta es [PortalSurveyAnswer.problem].
enum PortalSurveyProblem {
  invoiceNotFound('no_encontre_factura'),
  pageFailed('pagina_fallo'),
  paymentRejected('pago_rechazado'),
  noPaymentMethod('sin_medio_pago'),
  other('otro');

  const PortalSurveyProblem(this.value);

  final String value;
}

/// Paso de la encuesta en que el usuario la cerró.
enum PortalSurveyStep {
  question('pregunta'),
  problem('motivo');

  const PortalSurveyStep(this.value);

  final String value;
}

/// Desde dónde se abrió el tutorial.
enum TutorialOrigin {
  /// Solo, la primera vez que llega a la Home.
  firstUse('primer_uso'),

  /// «Ver tutorial de la app» en Ayuda y Soporte.
  help('ayuda');

  const TutorialOrigin(this.value);

  final String value;
}

/// Con qué botón terminó el tutorial (`tutorial_completado`).
enum TutorialClose {
  start('empezar'),
  login('iniciar_sesion'),
  signUp('crear_cuenta'),
  later('ahora_no');

  const TutorialClose(this.value);

  final String value;
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
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
    'Á': 'A',
    'À': 'A',
    'Ä': 'A',
    'Â': 'A',
    'É': 'E',
    'È': 'E',
    'Ë': 'E',
    'Ê': 'E',
    'Í': 'I',
    'Ì': 'I',
    'Ï': 'I',
    'Î': 'I',
    'Ó': 'O',
    'Ò': 'O',
    'Ö': 'O',
    'Ô': 'O',
    'Ú': 'U',
    'Ù': 'U',
    'Ü': 'U',
    'Û': 'U',
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
