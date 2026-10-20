import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';
import 'package:tramiapp_flutter/core/models/bank_dto.dart';
import 'package:tramiapp_flutter/core/models/department.dart';
import 'package:tramiapp_flutter/core/models/document_type_dto.dart';
import 'package:tramiapp_flutter/core/models/municipality_dto.dart';
import 'package:tramiapp_flutter/core/models/municipality_procedure.dart';
import 'package:tramiapp_flutter/core/models/reminders_by_user_dto.dart';
import 'package:tramiapp_flutter/core/models/shield_dto.dart';
import 'package:tramiapp_flutter/core/models/theme.dart' as model_theme;
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import 'package:tramiapp_flutter/core/notifications/local_reminder_scheduler.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/features/impuestos/domain/tax.dart';
import 'package:tramiapp_flutter/features/impuestos/presentation/respuesta_consulta_screen.dart';
import 'package:tramiapp_flutter/features/reminders/data/reminders_repository.dart';

import '../../helpers/fake_local_reminder_scheduler.dart';
import '../../support/recording_analytics.dart';

const _remindLabel = 'Recordarme antes del vencimiento';
const _loginTitle = 'Inicia sesión para recordarte';

Tax _tax({int taxId = 1, int dueInDays = 30}) {
  final now = DateTime.now();
  final due = DateTime(now.year, now.month, now.day + dueInDays);
  return Tax(
    entity: 'Alcaldía',
    entityCode: '05030',
    document: '123',
    name: 'Ana',
    taxName: 'Predial',
    taxId: taxId,
    value: 25000,
    invoice: 'FAC-1',
    reference: 'REF',
    dueDate: DateFormat('dd/MM/yyyy').format(due),
    queryField: '',
  );
}

MunicipalityDTO _municipality() => MunicipalityDTO(
  id: 1,
  name: 'Test',
  entityCode: '05030',
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
  municipalityProcedures: [
    MunicipalityProcedure.fromJson({
      'id': 500,
      'integrationType': '',
      'isActive': true,
      'procedures': {
        'id': 230,
        'name': 'Impuesto Predial Unificado',
        'code': 'PREDIAL',
        'kind': 'TAX',
        'externalId': 1,
      },
    }),
  ],
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
  email: 'ana@correo.co',
  firstName: 'Ana',
  lastName: 'Pérez',
  loginStatus: true,
  nationalId: '123',
  password: '',
  phoneNumber: '3001234567',
  birthDate: '1990-01-01',
);

class _Session extends SessionNotifier {
  _Session(this.initial);

  final UserDTO? initial;

  @override
  UserDTO? build() => initial;
}

class _EmptyReminders implements RemindersRepository {
  @override
  Future<List<RemindersByUserDto>> getRemindersByUser(int userId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<RecordingAnalytics> _pump(
  WidgetTester tester, {
  required List<Tax> taxes,
  UserDTO? user,
}) async {
  // El modal de creación es alto: pantalla de teléfono para que quepa.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final analytics = RecordingAnalytics();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _Session(user)),
        sharedPreferencesProvider.overrideWithValue(prefs),
        localReminderSchedulerProvider.overrideWithValue(
          FakeLocalReminderScheduler(),
        ),
        remindersRepositoryProvider.overrideWithValue(_EmptyReminders()),
        analyticsServiceProvider.overrideWithValue(analytics),
        municipalityProvider.overrideWith((ref, id) async => _municipality()),
      ],
      child: MaterialApp(
        home: TaxResultsScreen(municipalityId: 1, taxes: taxes, email: ''),
      ),
    ),
  );
  // Carga del municipio + entrada animada de las tarjetas.
  await tester.pumpAndSettle();
  return analytics;
}

void main() {
  testWidgets('factura vigente de un trámite del municipio: ofrece recordar', (
    tester,
  ) async {
    await _pump(tester, taxes: [_tax()]);

    expect(find.text(_remindLabel), findsOneWidget);
  });

  testWidgets('no lo ofrece si vence hoy o no es un trámite del municipio', (
    tester,
  ) async {
    await _pump(tester, taxes: [_tax(dueInDays: 0), _tax(taxId: 99)]);

    expect(find.text(_remindLabel), findsNothing);
  });

  testWidgets('sin sesión explica e invita a iniciar sesión; "Ahora no" no '
      'abre nada', (tester) async {
    final analytics = await _pump(tester, taxes: [_tax()]);

    await tester.tap(find.text(_remindLabel));
    await tester.pumpAndSettle();

    expect(find.text(_loginTitle), findsOneWidget);
    expect(analytics.single('recordatorio_iniciado'), {
      'municipio_id': 1,
      'origen': 'factura',
      'sesion': 'no',
    });

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(find.text(_loginTitle), findsNothing);
    expect(find.text('Añadir recordatorio'), findsNothing);
  });

  testWidgets('con sesión abre el modal ya lleno', (tester) async {
    final analytics = await _pump(tester, taxes: [_tax()], user: _user);

    await tester.tap(find.text(_remindLabel));
    await tester.pumpAndSettle();

    expect(find.text(_loginTitle), findsNothing);
    expect(find.text('Añadir recordatorio'), findsOneWidget);
    expect(find.text('Pagar Predial'), findsOneWidget);
    expect(find.text('Impuesto Predial Unificado'), findsOneWidget);
    // Antelación precargada en el selector "Avisarme".
    expect(find.text('1 día antes'), findsOneWidget);
    expect(analytics.single('recordatorio_iniciado')!['sesion'], 'si');
  });
}
