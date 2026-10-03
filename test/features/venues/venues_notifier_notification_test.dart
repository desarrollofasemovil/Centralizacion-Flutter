import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/models/venue_dto.dart';
import 'package:tramiapp_flutter/core/notifications/local_reminder_scheduler.dart';
import 'package:tramiapp_flutter/core/notifications/registration_notifications.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/features/venues/application/venues_notifier.dart';
import 'package:tramiapp_flutter/features/venues/data/venues_repository.dart';
import 'package:tramiapp_flutter/features/venues/domain/venues_state.dart';

import '../../helpers/fake_local_reminder_scheduler.dart';

const _venue = VenueDTO(id: 3, title: 'Cancha 1');

class _FakeVenuesRepository implements VenuesRepository {
  bool failReservation = false;

  @override
  Future<List<VenueDTO>> getVenues(int municipalityId, int venueId) async =>
      [_venue];

  @override
  Future<ReservationResponseDTO> createReservation(
    ReservationRequestDTO request,
  ) async {
    if (failReservation) throw Exception('El horario está ocupado');
    return const ReservationResponseDTO(message: 'Reserva creada');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingNotifications implements RegistrationNotifications {
  @override
  Future<bool> showCourseRegistration({
    required String courseTitle,
    required String userName,
  }) =>
      throw StateError('boom (síncrono)');

  @override
  Future<bool> showVenueReservation({
    required String venueTitle,
    required String userName,
    required String date,
    required String time,
  }) =>
      throw StateError('boom (síncrono)');
}

const _param = VenuesParam(
  municipalityId: 1,
  venueId: 0,
  municipalityEmail: '',
);

void main() {
  late FakeLocalReminderScheduler scheduler;
  late _FakeVenuesRepository repo;

  Future<ProviderContainer> makeContainer({
    List<Override> extra = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        venuesRepositoryProvider.overrideWithValue(repo),
        localReminderSchedulerProvider.overrideWithValue(scheduler),
        ...extra,
      ],
    );
    addTearDown(container.dispose);
    container.listen(venuesNotifierProvider(_param), (_, _) {});
    await Future<void>.delayed(Duration.zero); // microtask de _initForm
    await Future<void>.delayed(Duration.zero); // carga de escenarios
    return container;
  }

  VenuesNotifier fillForm(ProviderContainer c) {
    final n = c.read(venuesNotifierProvider(_param).notifier);
    n.onReserveClick(_venue);
    n.onFirstNameChange('Ana');
    n.onLastNameChange('Pérez');
    n.onDocumentNumberChange('123456');
    n.onEmailChange('ana@correo.co');
    n.onPhoneChange('3001234567');
    n.onDateChange('2026-10-10');
    n.onTimeChange('15:00');
    return n;
  }

  setUp(() {
    scheduler = FakeLocalReminderScheduler();
    repo = _FakeVenuesRepository();
  });

  test('reserva exitosa: notifica con título, nombre, fecha y hora', () async {
    final c = await makeContainer();
    final n = fillForm(c);

    await n.submitReservation();
    await Future<void>.delayed(Duration.zero);

    expect(
      c.read(venuesNotifierProvider(_param)).dialog?.type,
      ReservationDialogType.success,
    );
    expect(scheduler.shown, hasLength(1));
    final shown = scheduler.shown.single;
    final expected = venueReservationContent(
      venueTitle: 'Cancha 1',
      userName: 'Ana',
      date: '2026-10-10',
      time: '15:00',
    );
    expect(shown.id, kVenueNotificationId);
    expect(shown.title, expected.title);
    expect(shown.body, expected.body);
    expect(shown.bigText, expected.bigText);
  });

  test('reserva con error (catch): no notifica', () async {
    repo.failReservation = true;
    final c = await makeContainer();
    final n = fillForm(c);

    await n.submitReservation();
    await Future<void>.delayed(Duration.zero);

    final dialog = c.read(venuesNotifierProvider(_param)).dialog;
    expect(dialog?.type, ReservationDialogType.error);
    expect(dialog?.title, 'Aviso de Validación');
    expect(scheduler.shown, isEmpty);
  });

  test('si la notificación falla, la reserva igual queda como exitosa', () async {
    scheduler.throwOnShow = UnsupportedError('web');
    final c = await makeContainer();
    final n = fillForm(c);

    await n.submitReservation();
    await Future<void>.delayed(Duration.zero);

    expect(
      c.read(venuesNotifierProvider(_param)).dialog?.type,
      ReservationDialogType.success,
    );
  });

  test(
      'si el servicio de notificaciones lanza de forma síncrona, la reserva no se rompe',
      () async {
    final c = await makeContainer(
      extra: [
        registrationNotificationsProvider
            .overrideWithValue(_ThrowingNotifications()),
      ],
    );
    final n = fillForm(c);

    await n.submitReservation();
    await Future<void>.delayed(Duration.zero);

    expect(
      c.read(venuesNotifierProvider(_param)).dialog?.type,
      ReservationDialogType.success,
    );
  });

  test(
      'dos reservas seguidas usan el mismo id (la segunda reemplaza a la primera)',
      () async {
    final c = await makeContainer();
    final n = fillForm(c);
    await n.submitReservation();
    n.onDismissDialog();
    fillForm(c);
    await n.submitReservation();
    await Future<void>.delayed(Duration.zero);

    expect(scheduler.shown, hasLength(2));
    expect(scheduler.shown.map((s) => s.id).toSet(), {kVenueNotificationId});
  });
}
