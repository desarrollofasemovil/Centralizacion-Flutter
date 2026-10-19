import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/features/portal_externo/application/portal_visit_tracker.dart';
import 'package:tramiapp_flutter/features/portal_externo/presentation/portal_survey_sheet.dart';
import 'package:tramiapp_flutter/features/tramites/domain/info_tramite.dart';
import 'package:tramiapp_flutter/features/tramites/domain/procedure_identity.dart';

import '../../support/recording_analytics.dart';

const _url = 'https://baranoa-atlantico.softwaretributario.com/pagos?doc=123';

InfoTramite _tramite({ProcedureKind? kind = ProcedureKind.tax}) => InfoTramite(
  nombre: 'Impuesto Predial Unificado',
  icono: '',
  color: Colors.blue,
  accion: const AbrirUrl(_url),
  idtramite: 1,
  isActive: true,
  category: TramiteCategory.main,
  key: 'PREDIAL',
  kind: kind,
);

void main() {
  late RecordingAnalytics analytics;
  late DateTime now;
  late ProviderContainer container;

  Future<void> setUpContainer({
    bool detection = true,
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    analytics = RecordingAnalytics();
    now = DateTime(2026, 10, 19, 10);
    container = ProviderContainer(
      overrides: [
        analyticsServiceProvider.overrideWithValue(analytics),
        sharedPreferencesProvider.overrideWithValue(sp),
        portalClockProvider.overrideWithValue(() => now),
        portalReturnDetectionProvider.overrideWithValue(detection),
      ],
    );
    addTearDown(container.dispose);
  }

  PortalVisitTracker tracker() =>
      container.read(portalVisitTrackerProvider.notifier);

  /// Abre el portal, la app se oculta, pasa [away] y vuelve.
  void visit(Duration away, {InfoTramite? tramite}) {
    tracker().onPortalOpened(
      tramite ?? _tramite(),
      municipalityId: 59,
      url: _url,
    );
    tracker().onAppHidden();
    now = now.add(away);
    tracker().onAppResumed();
  }

  test(
    'abrir y volver registra apertura y regreso con el tiempo fuera',
    () async {
      await setUpContainer();
      visit(const Duration(minutes: 4));

      expect(analytics.names, [
        'portal_externo_abierto',
        'portal_externo_regreso',
      ]);
      final opened = analytics.single('portal_externo_abierto')!;
      expect(opened['url_dominio'], 'baranoa-atlantico.softwaretributario.com');
      expect(opened['tramite_codigo'], 'PREDIAL');
      expect(opened['municipio_id'], 59);
      final back = analytics.single('portal_externo_regreso')!;
      expect(back['segundos_fuera'], 240);
      expect(back['rango_tiempo'], '3_10min');
      expect(back['app_reiniciada'], 'no');
    },
  );

  test('impuesto con 20 s o más fuera: pide encuesta una sola vez', () async {
    await setUpContainer();
    visit(const Duration(seconds: 45));

    expect(container.read(portalVisitTrackerProvider).survey, isNotNull);
    final request = tracker().takeSurvey();
    expect(request, isNotNull);
    expect(request!.away, const Duration(seconds: 45));
    expect(tracker().takeSurvey(), isNull, reason: 'evento de un solo uso');
    expect(analytics.names.last, 'encuesta_portal_mostrada');
  });

  test('menos de 20 s fuera: no hay encuesta', () async {
    await setUpContainer();
    visit(const Duration(seconds: 10));
    expect(container.read(portalVisitTrackerProvider).survey, isNull);
  });

  test(
    'trámite que no es impuesto: mide el regreso pero no pregunta',
    () async {
      await setUpContainer();
      visit(
        const Duration(minutes: 2),
        tramite: _tramite(kind: ProcedureKind.other),
      );
      expect(analytics.names, contains('portal_externo_regreso'));
      expect(container.read(portalVisitTrackerProvider).survey, isNull);
    },
  );

  test('no repite la encuesta del mismo trámite antes de 15 días', () async {
    await setUpContainer();
    visit(const Duration(minutes: 1));
    tracker().takeSurvey();

    now = now.add(const Duration(days: 3));
    visit(const Duration(minutes: 1));
    expect(container.read(portalVisitTrackerProvider).survey, isNull);

    now = now.add(const Duration(days: 13));
    visit(const Duration(minutes: 1));
    expect(container.read(portalVisitTrackerProvider).survey, isNotNull);
  });

  test('un resumed sin haber ocultado la app no cuenta como regreso', () async {
    await setUpContainer();
    tracker().onPortalOpened(_tramite(), municipalityId: 59, url: _url);
    now = now.add(const Duration(minutes: 1));
    tracker().onAppResumed();
    expect(analytics.names, ['portal_externo_abierto']);
    expect(container.read(portalVisitTrackerProvider).active, isNotNull);
  });

  test('si no abrió el portal, no queda visita pendiente', () async {
    await setUpContainer();
    tracker().onPortalOpened(_tramite(), municipalityId: 59, url: _url);
    tracker().onPortalOpenFailed();
    tracker().onAppHidden();
    tracker().onAppResumed();
    expect(analytics.names, ['portal_externo_abierto']);
  });

  test('sin detección del regreso (iOS) solo registra la apertura', () async {
    await setUpContainer(detection: false);
    visit(const Duration(minutes: 5));
    expect(analytics.names, ['portal_externo_abierto']);
    expect(container.read(portalVisitTrackerProvider).survey, isNull);
  });

  test(
    'si Android cerró la app en el portal, se resuelve al volver a abrir',
    () async {
      await setUpContainer();
      tracker().onPortalOpened(_tramite(), municipalityId: 59, url: _url);
      final saved = container.read(sharedPreferencesProvider);

      // Proceso nuevo: memoria vacía, mismas preferencias en disco.
      final restarted = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(analytics),
          sharedPreferencesProvider.overrideWithValue(saved),
          portalClockProvider.overrideWithValue(() => now),
          portalReturnDetectionProvider.overrideWithValue(true),
        ],
      );
      addTearDown(restarted.dispose);
      now = now.add(const Duration(minutes: 3));
      restarted.read(portalVisitTrackerProvider.notifier).restorePendingVisit();

      final back = analytics.single('portal_externo_regreso')!;
      expect(back['app_reiniciada'], 'si');
      expect(back['segundos_fuera'], 180);
      expect(restarted.read(portalVisitTrackerProvider).survey, isNotNull);

      // Ya resuelta: no se vuelve a contar.
      restarted.read(portalVisitTrackerProvider.notifier).restorePendingVisit();
      expect(
        analytics.names.where((n) => n == 'portal_externo_regreso'),
        hasLength(1),
      );
    },
  );

  test('tras reinicio, más de 60 min fuera: regreso sí, encuesta no', () async {
    await setUpContainer();
    tracker().onPortalOpened(_tramite(), municipalityId: 59, url: _url);
    final saved = container.read(sharedPreferencesProvider);
    final restarted = ProviderContainer(
      overrides: [
        analyticsServiceProvider.overrideWithValue(analytics),
        sharedPreferencesProvider.overrideWithValue(saved),
        portalClockProvider.overrideWithValue(() => now),
        portalReturnDetectionProvider.overrideWithValue(true),
      ],
    );
    addTearDown(restarted.dispose);
    now = now.add(const Duration(hours: 5));
    restarted.read(portalVisitTrackerProvider.notifier).restorePendingVisit();
    expect(analytics.names, contains('portal_externo_regreso'));
    expect(restarted.read(portalVisitTrackerProvider).survey, isNull);
  });

  test('un regreso normal borra la visita guardada', () async {
    await setUpContainer();
    visit(const Duration(minutes: 1));
    tracker().restorePendingVisit();
    expect(
      analytics.names.where((n) => n == 'portal_externo_regreso'),
      hasLength(1),
    );
  });

  test('rangos de tiempo fuera', () {
    String r(int s) => AnalyticsService.timeAwayRange(Duration(seconds: s));
    expect(r(5), 'menos_15s');
    expect(r(15), '15_60s');
    expect(r(60), '1_3min');
    expect(r(180), '3_10min');
    expect(r(600), 'mas_10min');
  });

  group('PortalSurveySheet', () {
    Future<List<(PortalSurveyAnswer, PortalSurveyProblem?)>> pump(
      WidgetTester tester,
    ) async {
      final answers = <(PortalSurveyAnswer, PortalSurveyProblem?)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<bool>(
                  context: context,
                  builder: (_) => PortalSurveySheet(
                    tramiteName: 'Impuesto Predial Unificado',
                    onAnswered: (a, p) => answers.add((a, p)),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return answers;
    }

    testWidgets('un toque responde', (tester) async {
      final answers = await pump(tester);
      expect(find.text('¿Pudiste hacer tu pago?'), findsOneWidget);
      await tester.tap(find.text('Sí, pagué'));
      await tester.pump();
      expect(answers, [(PortalSurveyAnswer.paid, null)]);
    });

    testWidgets('"Tuve un problema" pide el motivo', (tester) async {
      final answers = await pump(tester);
      await tester.tap(find.text('Tuve un problema'));
      await tester.pump();
      expect(answers, isEmpty);
      expect(find.text('¿Qué pasó?'), findsOneWidget);
      await tester.tap(find.text('No encontré mi factura'));
      await tester.pump();
      expect(answers, [
        (PortalSurveyAnswer.problem, PortalSurveyProblem.invoiceNotFound),
      ]);
    });
  });

  test('la respuesta lleva el motivo solo si hubo problema', () async {
    await setUpContainer();
    visit(const Duration(minutes: 1));
    final request = tracker().takeSurvey()!;
    tracker().onSurveyAnswered(request, PortalSurveyAnswer.paid);
    expect(
      analytics.single('encuesta_portal_respuesta')!,
      isNot(contains('motivo')),
    );
    expect(
      analytics.single('encuesta_portal_respuesta')!['respuesta'],
      'pague',
    );
  });
}
