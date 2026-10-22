import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';
import 'package:tramiapp_flutter/core/models/bank_dto.dart';
import 'package:tramiapp_flutter/core/models/department.dart';
import 'package:tramiapp_flutter/core/models/document_type_dto.dart';
import 'package:tramiapp_flutter/core/models/municipality.dart';
import 'package:tramiapp_flutter/core/models/municipality_dto.dart';
import 'package:tramiapp_flutter/core/models/municipality_procedure.dart';
import 'package:tramiapp_flutter/core/models/procedures.dart';
import 'package:tramiapp_flutter/core/models/shield_dto.dart';
import 'package:tramiapp_flutter/core/models/theme.dart' as model_theme;
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/core/widgets/app_back_button.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/features/tutorial/application/tutorial_providers.dart';
import 'package:tramiapp_flutter/features/tutorial/domain/tutorial_config.dart';
import 'package:tramiapp_flutter/features/tutorial/presentation/tutorial_screen.dart';

import '../../support/recording_analytics.dart';

final _owner = Municipality(
  domain: 'rionegro.gov.co',
  id: 81,
  name: 'Rionegro',
  isActive: true,
);

/// Trámite por id legacy (1 Predial, 2 ICA, 4 PQRSDF) con su integración.
MunicipalityProcedure _procedure(int id, String name, String integration) =>
    MunicipalityProcedure(
      id: id,
      integrationType: integration,
      isActive: true,
      municipality: _owner,
      procedures: Procedures(id: id, name: name),
    );

/// Predial por PSV (en la app), ICA por portal y PQRSDF de la app.
final _withTaxesInApp = [
  _procedure(1, 'Impuesto Predial Unificado', 'psv'),
  _procedure(2, 'Industria y Comercio', 'https://pagos.gov.co/ica'),
  _procedure(4, 'PQRSDF', ''),
];

/// Solo el ICA por portal.
final _portalOnly = [
  _procedure(2, 'Industria y Comercio', 'https://pagos.gov.co/ica'),
];

/// Sin trámites (por defecto): el recorrido es 1-3B-6B (+7 sin sesión).
MunicipalityDTO _municipality([
  List<MunicipalityProcedure> procedures = const [],
]) => MunicipalityDTO(
  id: 81,
  name: 'Rionegro',
  entityCode: '',
  domain: 'rionegro.gov.co',
  isActive: true,
  department: Department(id: 1, name: 'Antioquia'),
  bank: BankDTO(nameBank: 'Banco'),
  idShield: ShieldDTO(municipalityName: 'Rionegro', url: ''),
  theme: model_theme.Theme(
    primaryColor: '0xFF005B8C',
    secondaryColor: '0xFF4364CD',
    secondaryColorBlack: '0xFFFFFFFF',
    onPrimaryColorLight: '0xFF000000',
    onPrimaryColorDark: '0xFFFFFFFF',
    backGroundColor: '0xFFF3F4F6',
  ),
  municipalityProcedures: procedures,
  municipalitySocialMedia: const [],
  courses: const [],
  sportsFacilities: const [],
  newsByMunicipalities: const [],
  queryFields: const [],
  passwordFintech: '',
  userFintech: '',
);

final _user = UserDTO(
  id: 7,
  address: 'Calle 1',
  documentType: DocumentTypeDTO(id: 1, name: 'CC'),
  documentTypeId: 1,
  email: 'u7@correo.co',
  firstName: 'Usuario',
  lastName: '7',
  loginStatus: true,
  nationalId: '7',
  password: '',
  phoneNumber: '300',
  birthDate: '1990-01-01',
);

class _Session extends SessionNotifier {
  _Session(this.user);

  final UserDTO? user;

  @override
  UserDTO? build() => user;
}

class _Harness {
  _Harness(this.analytics, this.prefs);

  final RecordingAnalytics analytics;
  final UserPreferences prefs;

  /// Lo que devolvió el `pop` del tutorial; `closed` dice si ya se cerró.
  TutorialClose? result;
  bool closed = false;
}

Future<_Harness> _open(
  WidgetTester tester, {
  bool hasSession = false,
  List<MunicipalityProcedure> procedures = const [],
}) async {
  tester.view.physicalSize = const Size(360, 800) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final shared = await SharedPreferences.getInstance();
  final harness = _Harness(RecordingAnalytics(), UserPreferences(shared));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(shared),
        analyticsServiceProvider.overrideWithValue(harness.analytics),
        tutorialConfigProvider.overrideWithValue(const TutorialConfig()),
        sessionProvider.overrideWith(() => _Session(hasSession ? _user : null)),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  harness.result = await Navigator.of(context).push(
                    MaterialPageRoute<TutorialClose>(
                      builder: (_) => TutorialScreen(
                        municipality: _municipality(procedures),
                        origin: TutorialOrigin.firstUse,
                      ),
                    ),
                  );
                  harness.closed = true;
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return harness;
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('Siguiente'));
  await tester.pumpAndSettle();
}

Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('al abrirse registra el recorrido y queda marcado como visto', (
    tester,
  ) async {
    final h = await _open(tester);

    expect(
      find.text('Bienvenido a la app de la Alcaldía de Rionegro'),
      findsOneWidget,
    );
    // En la primera tarjeta no hay "Atrás".
    expect(find.byType(AppBackButton), findsNothing);
    expect(h.prefs.tutorialSeen(), isTrue);
    expect(h.analytics.names, ['tutorial_iniciado', 'tutorial_paso_visto']);
    expect(h.analytics.single('tutorial_iniciado'), {
      'municipio_id': 81,
      'origen': 'primer_uso',
      'recorrido': '1-3B-6B-7',
      'pasos': 4,
    });
    expect(h.analytics.single('tutorial_paso_visto'), {
      'municipio_id': 81,
      'origen': 'primer_uso',
      'paso': 1,
      'tarjeta': '1',
    });
  });

  testWidgets('sin sesión termina en «Crea tu cuenta» y devuelve el botón', (
    tester,
  ) async {
    final h = await _open(tester);
    await _next(tester);
    expect(find.text('Que no se te pase ningún pago'), findsOneWidget);
    await _next(tester);
    await _next(tester);

    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.text('Siguiente'), findsNothing);
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(h.closed, isTrue);
    expect(h.result, TutorialClose.signUp);
    expect(h.analytics.single('tutorial_completado'), {
      'municipio_id': 81,
      'origen': 'primer_uso',
      'pasos': 4,
      'cierre': 'crear_cuenta',
    });
    expect(
      h.analytics.events
          .where((e) => e.$1 == 'tutorial_paso_visto')
          .map((e) => e.$2!['tarjeta']),
      ['1', '3B', '6B', '7'],
    );
  });

  testWidgets('con sesión la última tarjeta cierra con «Empezar»', (
    tester,
  ) async {
    final h = await _open(tester, hasSession: true);
    await _next(tester);
    await _next(tester);

    expect(find.text('Sigue tus pagos'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsNothing);
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    expect(h.result, TutorialClose.start);
    expect(h.analytics.single('tutorial_completado')!['cierre'], 'empezar');
  });

  testWidgets('«Omitir» cierra y registra en qué tarjeta iba', (tester) async {
    final h = await _open(tester);
    await _next(tester);
    await tester.tap(find.text('Omitir'));
    await tester.pumpAndSettle();

    expect(h.closed, isTrue);
    expect(h.result, isNull);
    expect(h.analytics.single('tutorial_omitido'), {
      'municipio_id': 81,
      'origen': 'primer_uso',
      'paso': 2,
      'tarjeta': '3B',
    });
    expect(h.analytics.names, isNot(contains('tutorial_completado')));
  });

  testWidgets('"Atrás" vuelve a la tarjeta anterior; en la primera, omite', (
    tester,
  ) async {
    final h = await _open(tester);
    await _next(tester);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    expect(
      find.text('Bienvenido a la app de la Alcaldía de Rionegro'),
      findsOneWidget,
    );
    expect(h.closed, isFalse);

    await _next(tester);
    await _systemBack(tester);
    expect(h.closed, isFalse);

    await _systemBack(tester);
    expect(h.closed, isTrue);
    expect(h.analytics.single('tutorial_omitido')!['paso'], 1);
  });

  testWidgets('con impuestos en la app: recorrido A completo', (tester) async {
    final h = await _open(
      tester,
      hasSession: true,
      procedures: _withTaxesInApp,
    );
    expect(
      h.analytics.single('tutorial_iniciado')!['recorrido'],
      '1-2A-3A-4-5-6A',
    );
    await _next(tester);
    expect(find.text('Paga tus impuestos en minutos'), findsOneWidget);
    await _next(tester);
    await _next(tester);
    // La 4 menciona las PQRSDF porque la alcaldía las tiene.
    expect(find.textContaining('envía tus PQRSDF'), findsOneWidget);
    await _next(tester);
    expect(find.text('¿Una petición, queja o reclamo?'), findsOneWidget);
    expect(find.textContaining('reconoces un buen servicio'), findsOneWidget);
    await _next(tester);
    expect(find.text('Empezar'), findsOneWidget);
  });

  testWidgets('solo portal: recorrido B', (tester) async {
    final h = await _open(tester, procedures: _portalOnly);
    expect(
      h.analytics.single('tutorial_iniciado')!['recorrido'],
      '1-2B-3B-6B-7',
    );
    await _next(tester);
    expect(
      find.text('Paga en el portal oficial de tu alcaldía'),
      findsOneWidget,
    );
  });

  for (final (name, procedures) in [
    ('sin trámites', const <MunicipalityProcedure>[]),
    ('impuestos en la app', _withTaxesInApp),
    ('solo portal', _portalOnly),
  ]) {
    testWidgets('con letra al 130 % no se desborda ninguna tarjeta ($name)', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final h = await _open(tester, procedures: procedures);
      final steps = h.analytics.single('tutorial_iniciado')!['pasos']! as int;
      for (var i = 1; i < steps - 1; i++) {
        await _next(tester);
        expect(tester.takeException(), isNull, reason: 'tarjeta ${i + 1}');
      }
      // La última sin sesión es la 7, sin «Siguiente».
      await _next(tester);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
