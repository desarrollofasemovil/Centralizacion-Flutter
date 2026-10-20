import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';
import 'package:tramiapp_flutter/core/models/document_type_dto.dart';
import 'package:tramiapp_flutter/core/models/municipality_dto.dart';
import 'package:tramiapp_flutter/core/models/reminders_by_user_dto.dart';
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import 'package:tramiapp_flutter/core/notifications/local_reminder_scheduler.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/features/reminders/data/reminders_repository.dart';
import 'package:tramiapp_flutter/features/reminders/presentation/reminders_screen.dart';
import 'package:tramiapp_flutter/features/reminders/presentation/upcoming_reminder_banner.dart';

import '../../helpers/fake_local_reminder_scheduler.dart';
import '../../support/recording_analytics.dart';

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

final _guest = UserDTO(
  id: 0,
  address: '',
  documentType: DocumentTypeDTO(id: 1, name: 'CC'),
  documentTypeId: 1,
  email: 'invitado@correo.co',
  firstName: 'Invitado',
  lastName: '',
  loginStatus: false,
  nationalId: '123',
  password: '',
  phoneNumber: '',
  birthDate: '',
);

String _inDays(int days) {
  final now = DateTime.now();
  return DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime(now.year, now.month, now.day + days));
}

class _Session extends SessionNotifier {
  _Session(this.initial);

  final UserDTO? initial;

  @override
  UserDTO? build() => initial;
}

class _Reminders implements RemindersRepository {
  _Reminders(this.items);

  final List<RemindersByUserDto> items;

  @override
  Future<List<RemindersByUserDto>> getRemindersByUser(int userId) async =>
      items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  UserDTO? user,
  List<RemindersByUserDto> reminders = const [],
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(() => _Session(user)),
        sharedPreferencesProvider.overrideWithValue(prefs),
        localReminderSchedulerProvider.overrideWithValue(
          FakeLocalReminderScheduler(),
        ),
        remindersRepositoryProvider.overrideWithValue(_Reminders(reminders)),
        analyticsServiceProvider.overrideWithValue(RecordingAnalytics()),
        // El municipio no hace falta para listar; el modal muestra su carga.
        municipalityProvider.overrideWith(
          (ref, id) => Future<MunicipalityDTO>.error('sin datos'),
        ),
      ],
      child: MaterialApp(home: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Mis recordatorios', () {
    testWidgets('sin sesión explica y ofrece iniciar sesión', (tester) async {
      await _pump(tester, const RemindersScreen(municipalityId: 1));

      expect(find.text('Que no se te pase ningún pago'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Crear recordatorio'), findsNothing);
    });

    testWidgets('el invitado (sin cuenta) cuenta como sin sesión', (
      tester,
    ) async {
      await _pump(
        tester,
        const RemindersScreen(municipalityId: 1),
        user: _guest,
      );

      expect(find.text('Que no se te pase ningún pago'), findsOneWidget);
    });

    testWidgets('con sesión y sin recordatorios: estado vacío y botón crear', (
      tester,
    ) async {
      await _pump(
        tester,
        const RemindersScreen(municipalityId: 1),
        user: _user,
      );

      expect(find.text('Aún no tienes recordatorios'), findsOneWidget);
      expect(find.text('Crear recordatorio'), findsOneWidget);
    });

    testWidgets('lista los próximos primero, con cuándo vencen', (
      tester,
    ) async {
      await _pump(
        tester,
        const RemindersScreen(municipalityId: 1),
        user: _user,
        reminders: [
          RemindersByUserDto(
            id: 1,
            reminderName: 'Pagar ICA',
            vigenciaDate: _inDays(10),
            reminderTime: '08:00',
          ),
          RemindersByUserDto(
            id: 2,
            reminderName: 'Pagar Predial',
            vigenciaDate: _inDays(1),
            reminderTime: '08:00',
          ),
        ],
      );

      final predial = tester.getTopLeft(find.text('Pagar Predial'));
      final ica = tester.getTopLeft(find.text('Pagar ICA'));
      expect(predial.dy, lessThan(ica.dy));
      expect(find.text('mañana'), findsOneWidget);
      expect(find.text('en 10 días'), findsOneWidget);
    });

    testWidgets('eliminar pide confirmación', (tester) async {
      await _pump(
        tester,
        const RemindersScreen(municipalityId: 1),
        user: _user,
        reminders: [
          RemindersByUserDto(
            id: 1,
            reminderName: 'Pagar ICA',
            vigenciaDate: _inDays(10),
            reminderTime: '08:00',
          ),
        ],
      );

      await tester.tap(find.byTooltip('Eliminar recordatorio'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar recordatorio'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('"Crear recordatorio" abre el modal con el selector de aviso', (
      tester,
    ) async {
      await _pump(
        tester,
        const RemindersScreen(municipalityId: 1),
        user: _user,
      );

      await tester.tap(find.text('Crear recordatorio'));
      // Sin trámites cargados el buscador del modal muestra un indicador de
      // carga que no termina: se avanza un tiempo fijo en vez de esperar.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Añadir recordatorio'), findsOneWidget);
      expect(find.text('Avisarme'), findsOneWidget);
    });
  });

  group('Aviso de la Home', () {
    Widget banner() => Scaffold(body: UpcomingReminderBanner(onTap: () {}));

    testWidgets('aparece con un recordatorio en los próximos 7 días', (
      tester,
    ) async {
      await _pump(
        tester,
        banner(),
        user: _user,
        reminders: [
          RemindersByUserDto(
            id: 1,
            reminderName: 'Pagar Predial',
            vigenciaDate: _inDays(1),
            reminderTime: '08:00',
          ),
        ],
      );

      expect(find.text('Tienes un recordatorio mañana'), findsOneWidget);
      expect(find.text('Pagar Predial · 08:00'), findsOneWidget);
    });

    testWidgets('no ocupa espacio si no hay nada próximo', (tester) async {
      await _pump(
        tester,
        banner(),
        user: _user,
        reminders: [
          RemindersByUserDto(
            id: 1,
            reminderName: 'Pagar ICA',
            vigenciaDate: _inDays(30),
            reminderTime: '08:00',
          ),
        ],
      );

      expect(find.textContaining('Tienes un recordatorio'), findsNothing);
    });

    testWidgets('sin sesión no aparece', (tester) async {
      await _pump(tester, banner());

      expect(find.textContaining('Tienes un recordatorio'), findsNothing);
    });
  });
}
