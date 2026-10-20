import '../../../core/models/reminders_by_user_dto.dart';

/// Fecha y hora de un recordatorio: `vigenciaDate` (día) + `reminderTime`
/// (`HH:mm` o `HH:mm:ss`). Sin hora válida se toma el inicio del día. `null`
/// si la fecha no se entiende.
DateTime? reminderDateTime(RemindersByUserDto reminder) {
  final date = DateTime.tryParse(reminder.vigenciaDate ?? '');
  if (date == null) return null;
  final parts = (reminder.reminderTime ?? '').split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) : null;
  return DateTime(date.year, date.month, date.day, hour ?? 0, minute ?? 0);
}

/// El recordatorio más cercano que todavía no ha pasado y cae dentro de
/// [window] desde [now]. Es el que se anuncia en la Home. `null` si no hay.
RemindersByUserDto? nextUpcomingReminder(
  List<RemindersByUserDto> reminders, {
  required DateTime now,
  Duration window = const Duration(days: 7),
}) {
  RemindersByUserDto? next;
  DateTime? nextAt;
  for (final reminder in reminders) {
    final at = reminderDateTime(reminder);
    if (at == null || at.isBefore(now) || at.isAfter(now.add(window))) {
      continue;
    }
    if (nextAt == null || at.isBefore(nextAt)) {
      next = reminder;
      nextAt = at;
    }
  }
  return next;
}

/// "hoy", "mañana" o "en N días", por días de calendario (no por horas).
String relativeDayLabel(DateTime date, {required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final days = day.difference(today).inDays;
  return switch (days) {
    0 => 'hoy',
    1 => 'mañana',
    _ => 'en $days días',
  };
}
