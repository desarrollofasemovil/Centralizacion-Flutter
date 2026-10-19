import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/storage/user_preferences.dart';
import '../../tramites/domain/info_tramite.dart';
import '../domain/portal_visit.dart';

export '../domain/portal_visit.dart';

/// Fase 2 de analítica: qué pasa cuando un trámite manda al contribuyente a un
/// portal externo (el portal tributario del municipio), donde la app ya no ve
/// nada. Custom Tabs / Safari VC no exponen la URL que el usuario visita, así
/// que se mide lo único observable — cuánto tiempo estuvo fuera — y, para los
/// impuestos, se pregunta con una microencuesta de un toque si pudo pagar.
///
/// Catálogo de eventos: `docs/ANALITICA_EVENTOS.md` (Fase 2).

/// Tiempo mínimo fuera para mostrar la encuesta: con menos, el usuario apenas
/// vio el portal y la pregunta no tiene sentido.
const Duration kPortalSurveyMinAway = Duration(seconds: 20);

/// Si la app se reinició mientras el usuario estaba en el portal, solo se
/// pregunta si vuelve antes de esto: pasado más tiempo, la visita ya no es lo
/// último que hizo y la respuesta no sería confiable.
const Duration kPortalSurveyMaxAwayAfterRestart = Duration(minutes: 60);

/// Una vez mostrada para un trámite de un municipio, no se vuelve a mostrar
/// para ese mismo trámite en este tiempo.
const Duration kPortalSurveyCooldown = Duration(days: 15);

/// La Home debe mostrar la encuesta de [visit] (el usuario estuvo [away] fuera).
class PortalSurveyRequest {
  const PortalSurveyRequest({required this.visit, required this.away});

  final PortalVisit visit;
  final Duration away;
}

class PortalVisitState {
  const PortalVisitState({this.active, this.survey});

  /// Portal abierto del que el usuario aún no ha vuelto.
  final PortalVisit? active;

  /// Encuesta pendiente de mostrar. Evento de un solo uso: la UI la consume
  /// con [PortalVisitTracker.takeSurvey].
  final PortalSurveyRequest? survey;
}

class PortalVisitTracker extends Notifier<PortalVisitState> {
  @override
  PortalVisitState build() => const PortalVisitState();

  /// La visita en curso también se guarda en disco: con la Custom Tab al
  /// frente, Android puede matar el proceso de la app (pasó en un Xiaomi a los
  /// 20 s), y sin esto el regreso y la encuesta se perdían.
  static const _kPendingVisit = 'portal_visit_pending';

  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);
  DateTime _now() => ref.read(portalClockProvider)();

  SharedPreferences? get _prefs {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null; // Sin preferencias (pruebas de widgets): solo en memoria.
    }
  }

  /// La app pasó a segundo plano después de abrir el portal. Sin esto, un
  /// `resumed` que no viene del portal (bajar la barra de notificaciones antes
  /// de que cargue la pestaña) se contaría como regreso.
  bool _leftApp = false;

  /// El portal de [tramite] se abrió en el navegador in-app.
  void onPortalOpened(
    InfoTramite tramite, {
    required int municipalityId,
    required String url,
  }) {
    final visit = PortalVisit(
      tramite: PortalTramite.fromInfoTramite(tramite),
      municipalityId: municipalityId,
      url: url,
      openedAt: _now(),
    );
    unawaited(_analytics.logPortalOpened(visit));
    // Sin detección del regreso (iOS, ver [portalReturnDetectionProvider]) no
    // se guarda la visita: el siguiente paso a segundo plano no tendría nada
    // que ver con el portal y mediría un tiempo falso.
    if (!ref.read(portalReturnDetectionProvider)) return;
    _leftApp = false;
    state = PortalVisitState(active: visit);
    unawaited(
      _prefs?.setString(_kPendingVisit, jsonEncode(visit.toJson())) ??
          Future.value(),
    );
  }

  /// No se pudo abrir el portal: no hay visita que medir.
  void onPortalOpenFailed() {
    if (state.active == null) return;
    state = const PortalVisitState();
    _clearPending();
  }

  /// La app dejó de estar visible (se abrió la pestaña del portal).
  void onAppHidden() {
    if (state.active != null) _leftApp = true;
  }

  /// La app volvió al primer plano. Si había un portal abierto y la app llegó
  /// a ocultarse, el usuario regresa de él.
  void onAppResumed() {
    final visit = state.active;
    if (visit == null || !_leftApp) return;
    _leftApp = false;
    _resolveReturn(visit, appRestarted: false);
  }

  /// Al montar la Home: si quedó una visita guardada de un proceso anterior
  /// (Android mató la app mientras el usuario estaba en el portal), el usuario
  /// vuelve ahora de ella.
  void restorePendingVisit() {
    if (state.active != null) return;
    final raw = _prefs?.getString(_kPendingVisit);
    if (raw == null) return;
    final PortalVisit visit;
    try {
      visit = PortalVisit.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _clearPending();
      return;
    }
    _resolveReturn(visit, appRestarted: true);
  }

  void _resolveReturn(PortalVisit visit, {required bool appRestarted}) {
    _clearPending();
    final away = _now().difference(visit.openedAt);
    unawaited(
      _analytics.logPortalReturned(
        visit,
        away: away,
        appRestarted: appRestarted,
      ),
    );
    final ask =
        _shouldAskSurvey(visit, away) &&
        (!appRestarted || away <= kPortalSurveyMaxAwayAfterRestart);
    state = PortalVisitState(
      survey: ask ? PortalSurveyRequest(visit: visit, away: away) : null,
    );
  }

  /// Entrega la encuesta pendiente (una sola vez), registra que se mostró y
  /// arranca el periodo sin volver a preguntar por ese trámite.
  PortalSurveyRequest? takeSurvey() {
    final request = state.survey;
    if (request == null) return null;
    state = const PortalVisitState();
    unawaited(
      _prefs?.setInt(
            _cooldownKey(request.visit),
            _now().millisecondsSinceEpoch,
          ) ??
          Future.value(),
    );
    unawaited(
      _analytics.logPortalSurveyShown(request.visit, away: request.away),
    );
    return request;
  }

  void onSurveyAnswered(
    PortalSurveyRequest request,
    PortalSurveyAnswer answer, {
    PortalSurveyProblem? problem,
  }) {
    unawaited(
      _analytics.logPortalSurveyAnswered(
        request.visit,
        away: request.away,
        answer: answer,
        problem: problem,
      ),
    );
  }

  void onSurveyDismissed(PortalSurveyRequest request, PortalSurveyStep step) {
    unawaited(_analytics.logPortalSurveyDismissed(request.visit, step: step));
  }

  /// Solo impuestos (la pregunta es por un pago), con tiempo suficiente fuera
  /// y sin haber preguntado por ese trámite hace poco.
  bool _shouldAskSurvey(PortalVisit visit, Duration away) {
    if (!visit.tramite.isTax) return false;
    if (away < kPortalSurveyMinAway) return false;
    final prefs = _prefs;
    if (prefs == null) return false;
    final last = prefs.getInt(_cooldownKey(visit));
    if (last == null) return true;
    final since = _now().difference(DateTime.fromMillisecondsSinceEpoch(last));
    return since >= kPortalSurveyCooldown;
  }

  void _clearPending() {
    unawaited(_prefs?.remove(_kPendingVisit) ?? Future.value());
  }

  static String _cooldownKey(PortalVisit visit) =>
      'portal_survey_last_${visit.municipalityId}_${visit.tramite.codigo}';
}

final portalVisitTrackerProvider =
    NotifierProvider<PortalVisitTracker, PortalVisitState>(
      PortalVisitTracker.new,
    );

/// Reloj de la visita (se sobreescribe en las pruebas).
final portalClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Si la plataforma avisa cuando el usuario vuelve del portal.
///
/// - **Android:** Chrome Custom Tabs es otra actividad; la de Flutter pasa a
///   segundo plano al abrirla y vuelve a `resumed` al cerrarla.
/// - **iOS:** Safari View Controller se presenta dentro de la app: el ciclo de
///   vida no cambia y `flutter_custom_tabs` no expone su `didFinish`. Hasta
///   tener esa señal nativa, en iOS solo se registra la apertura.
final portalReturnDetectionProvider = Provider<bool>(
  (_) => !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
);
