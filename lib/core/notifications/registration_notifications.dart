/// Notificaciones locales de confirmación al enviar una inscripción a un curso
/// o una reserva de escenario (port de `ui/components/NotificationHelper.kt`).

/// IDs de las notificaciones de confirmación. El Kotlin usaba `1` y `2`, pero
/// aquí los recordatorios usan el id del servidor (`created.id`, y `+1000000`
/// para la confirmación): `1` y `2` podían pisar un recordatorio real.
///
/// Dos envíos seguidos del mismo tipo comparten id, así que el segundo
/// reemplaza al primero (igual que en el Kotlin).
const int kCourseNotificationId = 2000001;
const int kVenueNotificationId = 2000002;

class NotificationContent {
  const NotificationContent({
    required this.title,
    required this.body,
    required this.bigText,
  });

  final String title;
  final String body;
  final String bigText;
}

NotificationContent courseRegistrationContent({
  required String courseTitle,
  required String userName,
}) {
  return NotificationContent(
    title: '¡Solicitud Enviada!',
    body: "$userName, hemos recibido tu solicitud para el curso '$courseTitle'. "
        'Un funcionario la revisará y te contactará pronto.',
    bigText: "$userName, tu solicitud de inscripción al curso '$courseTitle' "
        'ha sido enviada exitosamente. Un funcionario validará la información '
        'y se pondrá en contacto contigo.',
  );
}

NotificationContent venueReservationContent({
  required String venueTitle,
  required String userName,
  required String date,
  required String time,
}) {
  return NotificationContent(
    title: '¡Solicitud de Reserva Enviada!',
    body: "$userName, tu solicitud para '$venueTitle' ha sido enviada a revisión.",
    bigText: "$userName, la solicitud de reserva en '$venueTitle' para el "
        '$date a las $time ha sido enviada correctamente. Un funcionario '
        'validará la disponibilidad y se pondrá en contacto contigo pronto.',
  );
}
