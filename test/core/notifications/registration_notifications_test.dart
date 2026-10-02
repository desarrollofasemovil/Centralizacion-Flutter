import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/notifications/registration_notifications.dart';

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
}
