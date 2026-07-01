import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Programa notificaciones locales para los recordatorios (equivalente a la
/// lógica de `AlarmManager` del `RemindersViewModel` original de Android).
///
/// El original usa `AlarmManager.setExactAndAllowWhileIdle` + un
/// `BroadcastReceiver`. En Flutter usamos `zonedSchedule` de
/// `flutter_local_notifications`, que funciona igual en iOS y Android.
///
/// Como todos los municipios de Centralización son colombianos (zona
/// `America/Bogota`, UTC-5 sin horario de verano), fijamos la zona local a
/// esa ubicación en vez de añadir el paquete `flutter_timezone` solo para
/// leer la zona del sistema. (Desviación consciente respecto al
/// `ZoneId.systemDefault()` del original.)
class LocalReminderScheduler {
  LocalReminderScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelId = 'reminders_channel';

  bool _tzReady = false;

  void _ensureTz() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Bogota'));
    _tzReady = true;
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Recordatorios locales',
      channelDescription: 'Recordatorios de trámites y eventos',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Programa una notificación local para [dateTime]. Devuelve `true` si quedó
  /// agendada. Reintenta en modo inexacto si Android 12+ rechaza las alarmas
  /// exactas por falta del permiso `SCHEDULE_EXACT_ALARM`.
  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    _ensureTz();
    final scheduled = tz.TZDateTime.from(dateTime, tz.local);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return false;

    for (final mode in const [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]) {
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduled,
          notificationDetails: _details,
          androidScheduleMode: mode,
        );
        return true;
      } catch (e) {
        debugPrint('LocalReminderScheduler[$mode] error: $e');
      }
    }
    return false;
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }
}

final localReminderSchedulerProvider = Provider<LocalReminderScheduler>(
  (ref) => LocalReminderScheduler(FlutterLocalNotificationsPlugin()),
);
