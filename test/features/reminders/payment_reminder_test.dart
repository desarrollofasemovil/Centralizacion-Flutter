import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';
import 'package:tramiapp_flutter/core/api/services/api_providers.dart';
import 'package:tramiapp_flutter/core/api/services/payment_history_api_service.dart';
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
import 'package:tramiapp_flutter/features/historial_pagos/presentation/history_pay_screen.dart';
import 'package:tramiapp_flutter/features/reminders/application/reminders_notifier.dart';
import 'package:tramiapp_flutter/features/reminders/data/reminders_repository.dart';
import 'package:tramiapp_flutter/features/reminders/domain/reminders_state.dart';

import '../../helpers/fake_local_reminder_scheduler.dart';
import '../../support/recording_analytics.dart';

const _remindLabel = 'Recordarme el próximo pago';

final _predial = MunicipalityProcedure.fromJson({
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
});

final _certificado = MunicipalityProcedure.fromJson({
  'id': 501,
  'integrationType': '',
  'isActive': true,
  'procedures': {
    'id': 1,
    'name': 'Certificado de Residencia',
    'code': 'CERT_RESIDENCIA',
    'kind': 'CERTIFICATE',
    'externalId': 11,
  },
});

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

MunicipalityDTO _municipality() => MunicipalityDTO(
  id: 6,
  name: 'Copacabana',
  entityCode: '05212',
  domain: 'copacabana.gov.co',
  isActive: true,
  department: Department(id: 1, name: 'Antioquia'),
  bank: BankDTO(nameBank: 'Banco'),
  idShield: ShieldDTO(municipalityName: 'Copacabana', url: ''),
  theme: model_theme.Theme(
    primaryColor: '0xFF181E31',
    secondaryColor: '0xFF4364CD',
    secondaryColorBlack: '0xFFFFFFFF',
    onPrimaryColorLight: '0xFF000000',
    onPrimaryColorDark: '0xFFFFFFFF',
    backGroundColor: '0xFFF3F4F6',
  ),
  municipalityProcedures: [_predial, _certificado],
  municipalitySocialMedia: const [],
  courses: const [],
  sportsFacilities: const [],
  newsByMunicipalities: const [],
  queryFields: const [],
  passwordFintech: '',
  userFintech: '',
);

Map<String, dynamic> _payment({
  required int id,
  required String procedureName,
  required String idimpuesto,
  String statusType = 'APROBADA',
  String alcaldia = 'Copacabana',
  String paymentDate = '2026-10-15',
}) => {
  'id': id,
  'userFirtName': 'Ana',
  'amount': 250000,
  'paymentDate': paymentDate,
  'status': true,
  'idStatusType': statusType == 'APROBADA' ? 1 : 3,
  'alcaldia': alcaldia,
  'procedureName': procedureName,
  'statusType': statusType,
  'idimpuesto': idimpuesto,
  'factura': 'F-$id',
  'codigoEntidad': '05212',
};

class _Session extends SessionNotifier {
  _Session(this.initial);

  final UserDTO? initial;

  @override
  UserDTO? build() => initial;
}

class _HistoryApi implements PaymentHistoryApiService {
  _HistoryApi(this.items);

  final List<Map<String, dynamic>> items;

  @override
  Future<dynamic> getHistoryPaymentByUser(int id) async => items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoReminders implements RemindersRepository {
  @override
  Future<List<RemindersByUserDto>> getRemindersByUser(int userId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Future<RecordingAnalytics> _pumpHistory(
  WidgetTester tester,
  List<Map<String, dynamic>> payments,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final prefs = await _prefs();
  final analytics = RecordingAnalytics();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _Session(_user)),
        sharedPreferencesProvider.overrideWithValue(prefs),
        localReminderSchedulerProvider.overrideWithValue(
          FakeLocalReminderScheduler(),
        ),
        remindersRepositoryProvider.overrideWithValue(_NoReminders()),
        paymentHistoryApiServiceProvider.overrideWithValue(
          _HistoryApi(payments),
        ),
        analyticsServiceProvider.overrideWithValue(analytics),
        municipalityProvider.overrideWith((ref, id) async => _municipality()),
      ],
      child: const MaterialApp(home: HistoryPayScreen(municipalityId: 6)),
    ),
  );
  await tester.pumpAndSettle();
  return analytics;
}

void main() {
  group('suggestedNextDue', () {
    final now = DateTime(2026, 10, 21, 9);

    test('cuenta desde la fecha del pago', () {
      expect(
        suggestedNextDue(DateTime(2026, 10, 15), 3, now: now),
        DateTime(2027, 1, 15),
      );
      expect(
        suggestedNextDue(DateTime(2026, 10, 15), 12, now: now),
        DateTime(2027, 10, 15),
      );
    });

    test('un pago viejo cuya fecha ya pasó cuenta desde hoy', () {
      expect(
        suggestedNextDue(DateTime(2025, 1, 10), 3, now: now),
        DateTime(2027, 1, 21),
      );
    });

    test('si el día no existe en el mes destino usa el último', () {
      expect(addMonths(DateTime(2026, 11, 30), 3), DateTime(2027, 2, 28));
      expect(addMonths(DateTime(2027, 1, 31), 1), DateTime(2027, 2, 28));
    });
  });

  group('prefillFromPayment', () {
    late ProviderContainer container;

    setUp(() async {
      final prefs = await _prefs();
      container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(() => _Session(null)),
          sharedPreferencesProvider.overrideWithValue(prefs),
          localReminderSchedulerProvider.overrideWithValue(
            FakeLocalReminderScheduler(),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    int utcMillis(DateTime d) =>
        DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch;

    test('sugiere 1 año y avisa 1 semana antes; las opciones recalculan', () {
      final notifier = container.read(remindersNotifierProvider.notifier);
      final paidOn = DateTime.now().subtract(const Duration(days: 5));

      notifier.prefillFromPayment(
        procedure: _predial,
        name: 'Pagar Impuesto Predial Unificado',
        paidOn: paidOn,
      );
      var form = container.read(remindersNotifierProvider).formState;
      expect(form.origin, ReminderOrigin.payment);
      expect(form.recurrenceMonths, 12);
      expect(form.offset, ReminderOffset.oneWeek);
      expect(form.selectedDateMillis, utcMillis(addMonths(paidOn, 12)));

      notifier.selectRecurrence(3);
      form = container.read(remindersNotifierProvider).formState;
      expect(form.recurrenceMonths, 3);
      expect(form.selectedDateMillis, utcMillis(addMonths(paidOn, 3)));
    });

    test('cambiar la fecha a mano desmarca la opción rápida', () {
      final notifier = container.read(remindersNotifierProvider.notifier);
      notifier.prefillFromPayment(
        procedure: _predial,
        name: 'Pagar',
        paidOn: DateTime.now(),
      );

      notifier.updateFormDate(utcMillis(DateTime(2027, 3, 1)));

      final form = container.read(remindersNotifierProvider).formState;
      expect(form.recurrenceMonths, isNull);
      // Sigue siendo un recordatorio de pago: las opciones siguen a la vista.
      expect(form.paidOn, isNotNull);
    });
  });

  group('Historial: "Recordarme el próximo pago"', () {
    testWidgets('solo en pagos aprobados de un impuesto de este municipio', (
      tester,
    ) async {
      await _pumpHistory(tester, [
        _payment(id: 1, procedureName: 'Predial aprobado', idimpuesto: '1'),
        _payment(
          id: 2,
          procedureName: 'Predial fallido',
          idimpuesto: '1',
          statusType: 'FALLIDA',
        ),
        _payment(
          id: 3,
          procedureName: 'Predial de otra alcaldía',
          idimpuesto: '1',
          alcaldia: 'Bello',
        ),
        _payment(id: 4, procedureName: 'Certificado', idimpuesto: '11'),
      ]);

      expect(find.text(_remindLabel), findsOneWidget);
      // El botón está en la tarjeta del pago aprobado del predial.
      final button = tester.getTopLeft(find.text(_remindLabel));
      final approved = tester.getTopLeft(find.text('Predial aprobado'));
      final failed = tester.getTopLeft(find.text('Predial fallido'));
      expect(button.dy, greaterThan(approved.dy));
      expect(button.dy, lessThan(failed.dy));
    });

    testWidgets('abre el modal lleno con "¿Cuándo vuelve a vencer?"', (
      tester,
    ) async {
      final paidOn = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().subtract(const Duration(days: 5)));
      final analytics = await _pumpHistory(tester, [
        _payment(
          id: 1,
          procedureName: 'Predial',
          idimpuesto: '1',
          paymentDate: paidOn,
        ),
      ]);

      await tester.tap(find.text(_remindLabel));
      await tester.pumpAndSettle();

      expect(find.text('Añadir recordatorio'), findsOneWidget);
      expect(find.text('Pagar Impuesto Predial Unificado'), findsOneWidget);
      expect(find.text('¿Cuándo vuelve a vencer?'), findsOneWidget);
      final oneYear = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'En 1 año'),
      );
      expect(oneYear.selected, isTrue);
      expect(find.text('1 semana antes'), findsOneWidget);
      expect(analytics.single('recordatorio_iniciado'), {
        'municipio_id': 6,
        'origen': 'pago',
        'sesion': 'si',
      });

      // Elegir 3 meses cambia la fecha del campo.
      await tester.tap(find.widgetWithText(ChoiceChip, 'En 3 meses'));
      await tester.pumpAndSettle();
      final expected = addMonths(DateTime.parse(paidOn), 3);
      expect(
        find.text(DateFormat('dd/MM/yyyy').format(expected)),
        findsOneWidget,
      );
    });
  });
}
