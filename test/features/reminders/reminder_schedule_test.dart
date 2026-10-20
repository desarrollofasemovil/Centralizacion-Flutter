import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/models/reminders_by_user_dto.dart';
import 'package:tramiapp_flutter/features/reminders/domain/reminder_schedule.dart';

RemindersByUserDto _reminder(int id, String date, [String? time = '08:00']) =>
    RemindersByUserDto(
      id: id,
      vigenciaDate: date,
      reminderTime: time,
      reminderName: 'R$id',
    );

void main() {
  final now = DateTime(2026, 10, 20, 9);

  group('reminderDateTime', () {
    test('une la fecha y la hora', () {
      expect(
        reminderDateTime(_reminder(1, '2026-11-05', '14:30')),
        DateTime(2026, 11, 5, 14, 30),
      );
    });

    test('acepta la fecha con hora del backend y la hora con segundos', () {
      expect(
        reminderDateTime(_reminder(1, '2026-11-05T00:00:00', '07:15:00')),
        DateTime(2026, 11, 5, 7, 15),
      );
    });

    test('sin hora toma el inicio del día; sin fecha válida, null', () {
      expect(
        reminderDateTime(_reminder(1, '2026-11-05', null)),
        DateTime(2026, 11, 5),
      );
      expect(reminderDateTime(_reminder(1, 'sin fecha')), isNull);
    });
  });

  group('nextUpcomingReminder', () {
    test('elige el más cercano que aún no pasa', () {
      final next = nextUpcomingReminder([
        _reminder(1, '2026-10-25'),
        _reminder(2, '2026-10-21'),
        _reminder(3, '2026-10-20', '08:00'), // hoy, pero ya pasó (9:00)
      ], now: now);
      expect(next?.id, 2);
    });

    test('ignora los que caen fuera de la ventana de 7 días', () {
      expect(
        nextUpcomingReminder([_reminder(1, '2026-11-30')], now: now),
        isNull,
      );
    });

    test('hoy más tarde sí cuenta', () {
      expect(
        nextUpcomingReminder([
          _reminder(1, '2026-10-20', '18:00'),
        ], now: now)?.id,
        1,
      );
    });
  });

  test('relativeDayLabel cuenta días de calendario', () {
    expect(relativeDayLabel(DateTime(2026, 10, 20, 23), now: now), 'hoy');
    expect(relativeDayLabel(DateTime(2026, 10, 21, 1), now: now), 'mañana');
    expect(relativeDayLabel(DateTime(2026, 10, 24, 8), now: now), 'en 4 días');
  });
}
