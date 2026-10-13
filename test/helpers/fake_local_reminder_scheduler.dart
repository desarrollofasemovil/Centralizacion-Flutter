import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tramiapp_flutter/core/notifications/local_reminder_scheduler.dart';

class ShownNotification {
  ShownNotification(this.id, this.title, this.body, this.bigText);

  final int id;
  final String title;
  final String body;
  final String? bigText;
}

/// [LocalReminderScheduler] que no toca el plugin: registra lo que se mostraría.
class FakeLocalReminderScheduler extends LocalReminderScheduler {
  FakeLocalReminderScheduler() : super(FlutterLocalNotificationsPlugin());

  final shown = <ShownNotification>[];
  bool result = true;
  Object? throwOnShow;

  @override
  Future<bool> showNow({
    required int id,
    required String title,
    required String body,
    String? bigText,
  }) async {
    if (throwOnShow != null) throw throwOnShow!;
    shown.add(ShownNotification(id, title, body, bigText));
    return result;
  }
}
