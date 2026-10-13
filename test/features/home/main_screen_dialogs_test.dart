import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/flavor/flavor_config.dart';
import 'package:tramiapp_flutter/core/flavor/flavors.dart';
import 'package:tramiapp_flutter/core/models/bank_dto.dart';
import 'package:tramiapp_flutter/core/models/department.dart';
import 'package:tramiapp_flutter/core/models/municipality_dto.dart';
import 'package:tramiapp_flutter/core/models/shield_dto.dart';
import 'package:tramiapp_flutter/core/models/theme.dart' as model_theme;
import 'package:tramiapp_flutter/core/notifications/local_reminder_scheduler.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/features/home/application/main_viewmodel.dart';
import 'package:tramiapp_flutter/features/home/presentation/main_screen.dart';

import '../../helpers/fake_local_reminder_scheduler.dart';

const _id = 1;
const _devTitle = '¡Próximamente disponible!';
const _exitTitle = 'Atención';

MunicipalityDTO _municipality() => MunicipalityDTO(
  id: _id,
  name: 'Test',
  entityCode: 'ENT-001',
  domain: 'test.gov.co',
  isActive: true,
  department: Department(id: 1, name: 'Dept'),
  bank: BankDTO(nameBank: 'Banco'),
  idShield: ShieldDTO(municipalityName: 'Test', url: ''),
  theme: model_theme.Theme(
    primaryColor: '0xFF181E31',
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

Future<ProviderContainer> _pumpHome(WidgetTester tester) async {
  FlavorConfig.instance = flavorMunicipios;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localReminderSchedulerProvider.overrideWithValue(
          FakeLocalReminderScheduler(),
        ),
      ],
      child: MaterialApp(home: MainScreen(municipality: _municipality())),
    ),
  );
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(MainScreen)));
}

/// Fuerza N repintados de la Home con el flag todavía en `true` (lo que antes
/// encolaba un `showDialog` por repintado).
Future<void> _rebuildHome(WidgetTester tester, int times) async {
  for (var i = 0; i < times; i++) {
    tester.element(find.byType(MainScreen)).markNeedsBuild();
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 300));
}

/// "Atrás" del sistema + tiempo para la animación de salida del diálogo.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('"Próximamente": N repintados abren UN solo diálogo y Atrás '
      'resetea el flag', (tester) async {
    final container = await _pumpHome(tester);
    final notifier = container.read(mainViewModelProvider(_id).notifier);

    notifier.showInDevelopment();
    await _rebuildHome(tester, 5);
    expect(find.text(_devTitle), findsOneWidget);

    // Atrás del sistema cierra el diálogo sin pasar por "Entendido".
    await _systemBack(tester);
    expect(find.text(_devTitle), findsNothing);
    expect(
      container.read(mainViewModelProvider(_id)).showInDevelopmentDialog,
      isFalse,
    );

    // Con el flag reseteado, la siguiente transición vuelve a mostrarlo.
    notifier.showInDevelopment();
    await _rebuildHome(tester, 1);
    expect(find.text(_devTitle), findsOneWidget);

    await _unmount(tester);
  });

  testWidgets('salida: N repintados abren UN solo diálogo y Atrás resetea el '
      'flag', (tester) async {
    final container = await _pumpHome(tester);
    final notifier = container.read(mainViewModelProvider(_id).notifier);

    notifier.onBackPressed();
    await _rebuildHome(tester, 5);
    expect(find.text(_exitTitle), findsOneWidget);

    await _systemBack(tester);
    expect(find.text(_exitTitle), findsNothing);
    expect(container.read(mainViewModelProvider(_id)).showExitDialog, isFalse);

    await _unmount(tester);
  });
}
