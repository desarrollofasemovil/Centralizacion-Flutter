import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tramiapp_flutter/core/models/bank_dto.dart';
import 'package:tramiapp_flutter/core/models/department.dart';
import 'package:tramiapp_flutter/core/models/municipality_dto.dart';
import 'package:tramiapp_flutter/core/models/shield_dto.dart';
import 'package:tramiapp_flutter/core/models/theme.dart' as model_theme;
import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import 'package:tramiapp_flutter/features/pqrd/application/pqrd_notifier.dart';
import 'package:tramiapp_flutter/features/pqrd/presentation/pqrds_choice_screen.dart';

/// Pantalla de PQRSDF → tocar una tarjeta → aviso de Habeas Data con el enlace
/// a la Ley 1581 y Cancelar / Continuar → "Continuar" abre el formulario de
/// ESA tarjeta.

const _id = 1;
const _habeasUrl =
    'https://www.funcionpublica.gov.co/eva/gestornormativo/norma_pdf.php?i=49981';

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

/// No lanza los 18 GET de catálogos.
class _FakeDropdownOptions extends PqrdDropdownOptionsNotifier {
  final loaded = <String>[];

  @override
  Future<void> loadCatalogData(String codigoEntidad) async =>
      loaded.add(codigoEntidad);
}

Future<_FakeDropdownOptions> _pump(WidgetTester tester) async {
  final options = _FakeDropdownOptions();
  final router = GoRouter(
    initialLocation: '/municipality/$_id/pqrd',
    routes: [
      GoRoute(
        path: '/municipality/:id/pqrd',
        builder: (context, state) =>
            const PqrdsChoiceScreen(municipalityId: _id),
        routes: [
          GoRoute(
            path: 'anonima',
            builder: (context, state) =>
                const Scaffold(body: Text('formulario anónima')),
          ),
          GoRoute(
            path: 'identificada',
            builder: (context, state) =>
                const Scaffold(body: Text('formulario identificada')),
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        municipalityProvider(_id).overrideWith((ref) async => _municipality()),
        pqrdDropdownOptionsProvider.overrideWith(() => options),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return options;
}

Future<void> _tapCard(WidgetTester tester, String title) async {
  await tester.ensureVisible(find.text(title));
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el aviso trae el enlace de la ley y solo Cancelar / Continuar',
      (tester) async {
    await _pump(tester);
    await _tapCard(tester, 'P.Q.R.S.D Anónima');

    expect(find.text('Mensaje del sistema de información'), findsOneWidget);
    expect(find.text(_habeasUrl), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancelar'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continuar'), findsOneWidget);
    expect(find.text('PQRSDF Anónima'), findsNothing);
    expect(find.text('PQRSDF Identificación'), findsNothing);

    // Uno al lado del otro, mismo ancho, separados 5.
    final cancel = tester.getRect(find.widgetWithText(OutlinedButton, 'Cancelar'));
    final next = tester.getRect(find.widgetWithText(FilledButton, 'Continuar'));
    expect(cancel.top, next.top);
    expect(cancel.width, moreOrLessEquals(next.width, epsilon: 0.5));
    expect(next.left - cancel.right, moreOrLessEquals(5, epsilon: 0.5));
  });

  testWidgets('anónima → Continuar abre el formulario anónimo', (tester) async {
    final options = await _pump(tester);
    await _tapCard(tester, 'P.Q.R.S.D Anónima');

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('formulario anónima'), findsOneWidget);
    expect(options.loaded, ['ENT-001']);
  });

  testWidgets('identificada → Continuar abre el formulario con identificación',
      (tester) async {
    await _pump(tester);
    await _tapCard(tester, 'P.Q.R.S.D Identificada');

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('formulario identificada'), findsOneWidget);
  });

  testWidgets('Cancelar cierra el aviso y se queda en la pantalla',
      (tester) async {
    final options = await _pump(tester);
    await _tapCard(tester, 'P.Q.R.S.D Identificada');

    // La pantalla tiene su propio "Cancelar": se toca el del aviso.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Mensaje del sistema de información'), findsNothing);
    expect(find.text('Seleccione el tipo de PQRSDF'), findsOneWidget);
    expect(options.loaded, isEmpty);
  });
}
