import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// FIXME(reminders/notificaciones) — PENDIENTE DE ARREGLAR (revisar más adelante).
// La entrega de las notificaciones locales PROGRAMADAS de los recordatorios no
// es confiable todavía. La notificación inmediata de confirmación (`showNow`) sí
// aparece, pero la agendada con `zonedSchedule` no siempre se dispara a la hora.
// Puntos a investigar cuando se retome:
//   1. Android 12+ (API 31+): `exactAllowWhileIdle` requiere el permiso
//      SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM; si el usuario no lo concede caemos
//      a `inexactAllowWhileIdle` (agrupada por el sistema, puede llegar tarde).
//      Falta pedir/verificar `requestExactAlarmsPermission()` y declararlo en el
//      Manifest.
//   2. Optimización de batería / Doze de fabricantes (Xiaomi, Samsung, etc.)
//      puede matar la alarma. Considerar avisar al usuario o whitelisting.
//   3. Zona horaria fija `America/Bogota` (ver nota abajo) — validar el cálculo
//      del `TZDateTime` contra la hora local real del dispositivo.
//   4. iOS: sin verificar en iPhone físico (entorno sin Mac). Confirmar permisos
//      y entrega en background.
// Al retomar, actualizar también [[fase4-and-main-polish-status]].

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
  static const String _channelName = 'Recordatorios locales';
  static const String _channelDesc = 'Recordatorios de trámites y eventos';

  bool _tzReady = false;
  bool _initialized = false;

  void _ensureTz() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Bogota'));
    _tzReady = true;
  }

  /// Inicializa el plugin (ícono por defecto) y crea el canal de recordatorios.
  /// Autocontenido: no depende de que `PushNotificationsService.init()` corra.
  /// Sin esto, la alarma se dispara pero la notificación se descarta (sin canal
  /// ni ícono el sistema no la publica).
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_reminder'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_reminder',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// Pide el permiso de notificaciones (Android 13+). En iOS lo solicita el
  /// plugin al inicializar. Idempotente: si ya está concedido retorna al vuelo.
  Future<void> ensureNotificationPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }
  }

  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    await _ensureInitialized();
    await ensureNotificationPermission();
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

  /// Muestra una notificación inmediata (confirmación al crear el recordatorio
  /// y, de paso, prueba directa del canal de posteo).
  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _ensureInitialized();
      await ensureNotificationPermission();
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
      );
      return true;
    } catch (e) {
      debugPrint('LocalReminderScheduler.showNow error: $e');
      return false;
    }
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
