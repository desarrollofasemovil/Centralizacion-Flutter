import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/notifications/local_reminder_scheduler.dart';
import 'package:tramiapp_flutter/core/notifications/registration_notifications.dart';

import '../../helpers/fake_local_reminder_scheduler.dart';

void main() {
  group('contenido', () {
    test('curso: título, cuerpo y texto largo exactos', () {
      final c = courseRegistrationContent(courseTitle: 'Yoga', userName: 'Ana');

      expect(c.title, '¡Solicitud Enviada!');
      expect(
        c.body,
        "Ana, hemos recibido tu solicitud para el curso 'Yoga'. Un funcionario la revisará y te contactará pronto.",
      );
      expect(
        c.bigText,
        "Ana, tu solicitud de inscripción al curso 'Yoga' ha sido enviada exitosamente. Un funcionario validará la información y se pondrá en contacto contigo.",
      );
    });

    test('escenario: título, cuerpo y texto largo exactos', () {
      final c = venueReservationContent(
        venueTitle: 'Cancha 1',
        userName: 'Ana',
        date: '2026-10-10',
        time: '15:00',
      );

      expect(c.title, '¡Solicitud de Reserva Enviada!');
      expect(
        c.body,
        "Ana, tu solicitud para 'Cancha 1' ha sido enviada a revisión.",
      );
      expect(
        c.bigText,
        "Ana, la solicitud de reserva en 'Cancha 1' para el 2026-10-10 a las 15:00 ha sido enviada correctamente. Un funcionario validará la disponibilidad y se pondrá en contacto contigo pronto.",
      );
    });

    test('comillas, tildes y títulos largos pasan intactos', () {
      const tricky = "Niño's  Fútbol \"Élite\"";
      final long = 'Escuela de formación deportiva ' * 10; // > 300 caracteres

      final course = courseRegistrationContent(
        courseTitle: tricky,
        userName: 'José',
      );
      final venue = venueReservationContent(
        venueTitle: long,
        userName: 'José',
        date: '2026-10-10',
        time: '15:00',
      );

      expect(course.body, contains("curso '$tricky'."));
      expect(course.bigText, contains("curso '$tricky' ha sido"));
      expect(long.length, greaterThan(300));
      expect(venue.body, "José, tu solicitud para '$long' ha sido enviada a revisión.");
      expect(venue.bigText, contains("reserva en '$long' para el"));
    });

    test('ids distintos entre sí y fuera del rango de recordatorios del servidor',
        () {
      expect(kCourseNotificationId, 2000001);
      expect(kVenueNotificationId, 2000002);
      expect(kCourseNotificationId, isNot(kVenueNotificationId));
    });
  });

  group('servicio RegistrationNotifications', () {
    late FakeLocalReminderScheduler scheduler;
    late RegistrationNotifications service;

    setUp(() {
      scheduler = FakeLocalReminderScheduler();
      service = RegistrationNotifications(scheduler);
    });

    test('showCourseRegistration publica con id, título, cuerpo y bigText del curso',
        () async {
      final ok = await service.showCourseRegistration(
        courseTitle: 'Yoga',
        userName: 'Ana',
      );

      final expected = courseRegistrationContent(
        courseTitle: 'Yoga',
        userName: 'Ana',
      );
      expect(ok, isTrue);
      expect(scheduler.shown, hasLength(1));
      expect(scheduler.shown.single.id, kCourseNotificationId);
      expect(scheduler.shown.single.title, expected.title);
      expect(scheduler.shown.single.body, expected.body);
      expect(scheduler.shown.single.bigText, expected.bigText);
    });

    test('showVenueReservation publica con kVenueNotificationId', () async {
      final ok = await service.showVenueReservation(
        venueTitle: 'Cancha 1',
        userName: 'Ana',
        date: '2026-10-10',
        time: '15:00',
      );

      final expected = venueReservationContent(
        venueTitle: 'Cancha 1',
        userName: 'Ana',
        date: '2026-10-10',
        time: '15:00',
      );
      expect(ok, isTrue);
      expect(scheduler.shown.single.id, kVenueNotificationId);
      expect(scheduler.shown.single.title, expected.title);
      expect(scheduler.shown.single.bigText, expected.bigText);
    });

    test('si showNow devuelve false (permiso denegado) el servicio devuelve false y no lanza',
        () async {
      scheduler.result = false;

      final ok = await service.showCourseRegistration(
        courseTitle: 'Yoga',
        userName: 'Ana',
      );

      expect(ok, isFalse);
    });

    test('si showNow lanza, el servicio lo captura y devuelve false (p. ej. web)',
        () async {
      scheduler.throwOnShow = UnsupportedError('web');

      final course = await service.showCourseRegistration(
        courseTitle: 'Yoga',
        userName: 'Ana',
      );
      final venue = await service.showVenueReservation(
        venueTitle: 'Cancha 1',
        userName: 'Ana',
        date: '2026-10-10',
        time: '15:00',
      );

      expect(course, isFalse);
      expect(venue, isFalse);
    });
  });

  group('LocalReminderScheduler.buildDetails', () {
    test('con bigText usa BigTextStyleInformation con ese texto', () {
      final details = LocalReminderScheduler.buildDetails(bigText: 'texto largo');

      final style = details.android!.styleInformation;
      expect(style, isA<BigTextStyleInformation>());
      expect((style as BigTextStyleInformation).bigText, 'texto largo');
    });

    test('con bigText conserva canal, ícono e importancia de los recordatorios',
        () {
      final base = LocalReminderScheduler.buildDetails();
      final big = LocalReminderScheduler.buildDetails(bigText: 'x');

      expect(big.android!.channelId, base.android!.channelId);
      expect(big.android!.icon, 'ic_stat_reminder');
      expect(big.android!.importance, Importance.high);
      expect(big.android!.priority, Priority.high);
    });

    test('sin bigText no cambia el estilo (retrocompatible)', () {
      final details = LocalReminderScheduler.buildDetails();

      expect(details.android!.styleInformation, isNull);
    });
  });
}
