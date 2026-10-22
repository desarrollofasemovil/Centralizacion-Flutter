import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';
import 'package:tramiapp_flutter/core/flavor/flavor_config.dart';
import 'package:tramiapp_flutter/core/flavor/flavors.dart';
import 'package:tramiapp_flutter/core/models/bank_dto.dart';
import 'package:tramiapp_flutter/core/models/department.dart';
import 'package:tramiapp_flutter/core/models/municipality_dto.dart';
import 'package:tramiapp_flutter/core/models/shield_dto.dart';
import 'package:tramiapp_flutter/core/models/theme.dart' as model_theme;
import 'package:tramiapp_flutter/core/notifications/local_reminder_scheduler.dart';
import 'package:tramiapp_flutter/core/router/app_routes.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/features/home/presentation/main_screen.dart';
import 'package:tramiapp_flutter/features/tutorial/application/tutorial_providers.dart';
import 'package:tramiapp_flutter/features/tutorial/domain/tutorial_config.dart';

import '../../helpers/fake_local_reminder_scheduler.dart';

MunicipalityDTO _municipality() => MunicipalityDTO(
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
  municipalityProcedures: const [],
  municipalitySocialMedia: const [],
  courses: const [],
  sportsFacilities: const [],
  newsByMunicipalities: const [],
  queryFields: const [],
  passwordFintech: '',
  userFintech: '',
);

/// Monta la Home con una ruta de tutorial de mentira y devuelve cuántas veces
/// se abrió.
Future<List<TutorialOrigin>> _pumpHome(
  WidgetTester tester, {
  required Map<String, Object> prefs,
  TutorialConfig config = const TutorialConfig(),
}) async {
  FlavorConfig.instance = flavorMunicipios;
  SharedPreferences.setMockInitialValues(prefs);
  final shared = await SharedPreferences.getInstance();
  final opened = <TutorialOrigin>[];
  final router = GoRouter(
    initialLocation: AppRoutes.municipalityPath(81),
    routes: [
      GoRoute(
        path: AppRoutes.municipality,
        builder: (_, _) => MainScreen(municipality: _municipality()),
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        builder: (_, state) {
          opened.add(state.extra! as TutorialOrigin);
          return const Text('tutorial');
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(shared),
        localReminderSchedulerProvider.overrideWithValue(
          FakeLocalReminderScheduler(),
        ),
        tutorialConfigProvider.overrideWithValue(config),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return opened;
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('la primera vez que llega a la Home se abre el tutorial', (
    tester,
  ) async {
    final opened = await _pumpHome(tester, prefs: {});
    expect(opened, [TutorialOrigin.firstUse]);
    expect(find.text('tutorial'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('si ya lo vio en esta instalación, no', (tester) async {
    final opened = await _pumpHome(
      tester,
      prefs: {'tutorial_primer_uso_visto': true},
    );
    expect(opened, isEmpty);
    await _unmount(tester);
  });

  testWidgets('con el interruptor apagado, no', (tester) async {
    final opened = await _pumpHome(
      tester,
      prefs: {},
      config: const TutorialConfig(enabled: false),
    );
    expect(opened, isEmpty);
    await _unmount(tester);
  });
}
